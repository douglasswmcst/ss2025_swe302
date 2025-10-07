package repository

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"testing"
	"time"

	_ "github.com/lib/pq"
	"github.com/redis/go-redis/v9"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	redisTC "github.com/testcontainers/testcontainers-go/modules/redis"
	"github.com/testcontainers/testcontainers-go/wait"
)

var (
	cachedTestDB    *sql.DB
	cachedTestRedis *redis.Client
)

func TestMain(m *testing.M) {
	ctx := context.Background()

	// Start PostgreSQL container
	postgresContainer, err := postgres.RunContainer(ctx,
		testcontainers.WithImage("postgres:15-alpine"),
		postgres.WithDatabase("testdb"),
		postgres.WithUsername("testuser"),
		postgres.WithPassword("testpass"),
		postgres.WithInitScripts("../migrations/init.sql"),
		testcontainers.WithWaitStrategy(
			wait.ForLog("database system is ready to accept connections").
				WithOccurrence(2).
				WithStartupTimeout(5*time.Second)),
	)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to start postgres: %v\n", err)
		os.Exit(1)
	}

	// Start Redis container
	redisContainer, err := redisTC.RunContainer(ctx,
		testcontainers.WithImage("redis:7-alpine"),
		testcontainers.WithWaitStrategy(
			wait.ForLog("Ready to accept connections").
				WithStartupTimeout(5*time.Second)),
	)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to start redis: %v\n", err)
		os.Exit(1)
	}

	defer func() {
		postgresContainer.Terminate(ctx)
		redisContainer.Terminate(ctx)
	}()

	// Setup PostgreSQL connection
	pgConnStr, err := postgresContainer.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to get postgres connection: %v\n", err)
		os.Exit(1)
	}

	cachedTestDB, err = sql.Open("postgres", pgConnStr)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to connect to postgres: %v\n", err)
		os.Exit(1)
	}

	// Setup Redis connection
	redisHost, err := redisContainer.Host(ctx)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to get redis host: %v\n", err)
		os.Exit(1)
	}

	redisPort, err := redisContainer.MappedPort(ctx, "6379")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to get redis port: %v\n", err)
		os.Exit(1)
	}

	cachedTestRedis = redis.NewClient(&redis.Options{
		Addr: fmt.Sprintf("%s:%s", redisHost, redisPort.Port()),
	})

	// Verify connections
	if err = cachedTestDB.Ping(); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to ping postgres: %v\n", err)
		os.Exit(1)
	}

	if err = cachedTestRedis.Ping(ctx).Err(); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to ping redis: %v\n", err)
		os.Exit(1)
	}

	code := m.Run()
	cachedTestDB.Close()
	cachedTestRedis.Close()
	os.Exit(code)
}

func TestCachedGetByID(t *testing.T) {
	ctx := context.Background()
	repo := NewCachedUserRepository(cachedTestDB, cachedTestRedis)

	// Clear cache before test
	cachedTestRedis.FlushAll(ctx)

	t.Run("Cache Miss Then Hit", func(t *testing.T) {
		// First call - cache miss
		user1, err := repo.GetByIDCached(ctx, 1)
		if err != nil {
			t.Fatalf("Failed to get user: %v", err)
		}

		// Second call - should hit cache
		user2, err := repo.GetByIDCached(ctx, 1)
		if err != nil {
			t.Fatalf("Failed to get cached user: %v", err)
		}

		// Verify both calls return same data
		if user1.Email != user2.Email {
			t.Errorf("Cache returned different data")
		}

		// Verify cache was populated
		cacheKey := "user:1"
		exists, err := cachedTestRedis.Exists(ctx, cacheKey).Result()
		if err != nil {
			t.Fatalf("Failed to check cache: %v", err)
		}
		if exists != 1 {
			t.Error("Expected cache to be populated")
		}
	})
}

func TestCachedCreate(t *testing.T) {
	ctx := context.Background()
	repo := NewCachedUserRepository(cachedTestDB, cachedTestRedis)

	cachedTestRedis.FlushAll(ctx)

	user, err := repo.CreateCached(ctx, "cached@example.com", "Cached User")
	if err != nil {
		t.Fatalf("Failed to create cached user: %v", err)
	}
	defer repo.DeleteCached(ctx, user.ID)

	// Verify cache was populated
	cacheKey := fmt.Sprintf("user:%d", user.ID)
	exists, _ := cachedTestRedis.Exists(ctx, cacheKey).Result()
	if exists != 1 {
		t.Error("Expected cache to be populated after create")
	}

	// Verify reading from cache works
	cachedUser, err := repo.GetByIDCached(ctx, user.ID)
	if err != nil {
		t.Fatalf("Failed to get cached user: %v", err)
	}

	if cachedUser.Email != "cached@example.com" {
		t.Errorf("Cache returned wrong data: %s", cachedUser.Email)
	}
}

func TestCachedUpdate(t *testing.T) {
	ctx := context.Background()
	repo := NewCachedUserRepository(cachedTestDB, cachedTestRedis)

	cachedTestRedis.FlushAll(ctx)

	// Create user
	user, _ := repo.CreateCached(ctx, "update@example.com", "Update User")
	defer repo.DeleteCached(ctx, user.ID)

	// Cache the user
	repo.GetByIDCached(ctx, user.ID)

	// Update user (should invalidate cache)
	err := repo.UpdateCached(ctx, user.ID, "updated@example.com", "Updated Name")
	if err != nil {
		t.Fatalf("Failed to update user: %v", err)
	}

	// Verify cache was invalidated
	cacheKey := fmt.Sprintf("user:%d", user.ID)
	exists, _ := cachedTestRedis.Exists(ctx, cacheKey).Result()
	if exists == 1 {
		t.Error("Expected cache to be invalidated after update")
	}

	// Get user again (should fetch from DB)
	updatedUser, err := repo.GetByIDCached(ctx, user.ID)
	if err != nil {
		t.Fatalf("Failed to get updated user: %v", err)
	}

	if updatedUser.Email != "updated@example.com" {
		t.Errorf("Expected updated email, got: %s", updatedUser.Email)
	}
}

func TestCachedDelete(t *testing.T) {
	ctx := context.Background()
	repo := NewCachedUserRepository(cachedTestDB, cachedTestRedis)

	cachedTestRedis.FlushAll(ctx)

	// Create and cache user
	user, _ := repo.CreateCached(ctx, "delete@example.com", "Delete User")
	repo.GetByIDCached(ctx, user.ID)

	// Delete user
	err := repo.DeleteCached(ctx, user.ID)
	if err != nil {
		t.Fatalf("Failed to delete user: %v", err)
	}

	// Verify cache was invalidated
	cacheKey := fmt.Sprintf("user:%d", user.ID)
	exists, _ := cachedTestRedis.Exists(ctx, cacheKey).Result()
	if exists == 1 {
		t.Error("Expected cache to be invalidated after delete")
	}

	// Verify user is gone
	_, err = repo.GetByIDCached(ctx, user.ID)
	if err == nil {
		t.Error("Expected error for deleted user")
	}
}

func TestCacheExpiration(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping cache expiration test in short mode")
	}

	ctx := context.Background()
	repo := NewCachedUserRepository(cachedTestDB, cachedTestRedis)

	cachedTestRedis.FlushAll(ctx)

	// This test would verify TTL, but takes time
	// For brevity, we'll just verify TTL is set
	user, _ := repo.CreateCached(ctx, "ttl@example.com", "TTL User")
	defer repo.DeleteCached(ctx, user.ID)

	cacheKey := fmt.Sprintf("user:%d", user.ID)
	ttl, err := cachedTestRedis.TTL(ctx, cacheKey).Result()
	if err != nil {
		t.Fatalf("Failed to get TTL: %v", err)
	}

	if ttl <= 0 {
		t.Error("Expected positive TTL for cached item")
	}

	if ttl > 5*time.Minute {
		t.Errorf("Expected TTL <= 5 minutes, got: %v", ttl)
	}
}

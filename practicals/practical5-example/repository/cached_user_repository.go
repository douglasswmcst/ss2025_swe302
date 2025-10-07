package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"practical5-example/models"
	"time"

	"github.com/redis/go-redis/v9"
)

// CachedUserRepository wraps UserRepository with Redis caching
type CachedUserRepository struct {
	repo  *UserRepository
	cache *redis.Client
}

// NewCachedUserRepository creates a cached repository
func NewCachedUserRepository(db *sql.DB, cache *redis.Client) *CachedUserRepository {
	return &CachedUserRepository{
		repo:  NewUserRepository(db),
		cache: cache,
	}
}

// GetByIDCached retrieves user by ID with caching
func (r *CachedUserRepository) GetByIDCached(ctx context.Context, id int) (*models.User, error) {
	cacheKey := fmt.Sprintf("user:%d", id)

	// Try cache first
	cached, err := r.cache.Get(ctx, cacheKey).Result()
	if err == nil {
		var user models.User
		if err := json.Unmarshal([]byte(cached), &user); err == nil {
			return &user, nil
		}
	}

	// Cache miss - query database
	user, err := r.repo.GetByID(id)
	if err != nil {
		return nil, err
	}

	// Store in cache
	data, _ := json.Marshal(user)
	r.cache.Set(ctx, cacheKey, data, 5*time.Minute)

	return user, nil
}

// CreateCached creates a user and caches it
func (r *CachedUserRepository) CreateCached(ctx context.Context, email, name string) (*models.User, error) {
	user, err := r.repo.Create(email, name)
	if err != nil {
		return nil, err
	}

	// Cache the new user
	cacheKey := fmt.Sprintf("user:%d", user.ID)
	data, _ := json.Marshal(user)
	r.cache.Set(ctx, cacheKey, data, 5*time.Minute)

	return user, nil
}

// UpdateCached updates a user and invalidates cache
func (r *CachedUserRepository) UpdateCached(ctx context.Context, id int, email, name string) error {
	err := r.repo.Update(id, email, name)
	if err != nil {
		return err
	}

	// Invalidate cache
	cacheKey := fmt.Sprintf("user:%d", id)
	r.cache.Del(ctx, cacheKey)

	return nil
}

// DeleteCached deletes a user and invalidates cache
func (r *CachedUserRepository) DeleteCached(ctx context.Context, id int) error {
	err := r.repo.Delete(id)
	if err != nil {
		return err
	}

	// Invalidate cache
	cacheKey := fmt.Sprintf("user:%d", id)
	r.cache.Del(ctx, cacheKey)

	return nil
}

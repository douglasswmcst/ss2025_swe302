package repository

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"testing"
	"time"

	_ "github.com/lib/pq"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"
)

var testDB *sql.DB

func TestMain(m *testing.M) {
	ctx := context.Background()

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
		fmt.Fprintf(os.Stderr, "Failed to start container: %v\n", err)
		os.Exit(1)
	}

	defer func() {
		if err := postgresContainer.Terminate(ctx); err != nil {
			fmt.Fprintf(os.Stderr, "Failed to terminate container: %v\n", err)
		}
	}()

	connStr, err := postgresContainer.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to get connection string: %v\n", err)
		os.Exit(1)
	}

	testDB, err = sql.Open("postgres", connStr)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to connect to database: %v\n", err)
		os.Exit(1)
	}

	if err = testDB.Ping(); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to ping database: %v\n", err)
		os.Exit(1)
	}

	code := m.Run()
	testDB.Close()
	os.Exit(code)
}

func TestGetByID(t *testing.T) {
	repo := NewUserRepository(testDB)

	t.Run("User Exists", func(t *testing.T) {
		user, err := repo.GetByID(1)
		if err != nil {
			t.Fatalf("Expected no error, got: %v", err)
		}

		if user.Email != "alice@example.com" {
			t.Errorf("Expected email 'alice@example.com', got: %s", user.Email)
		}

		if user.Name != "Alice Smith" {
			t.Errorf("Expected name 'Alice Smith', got: %s", user.Name)
		}
	})

	t.Run("User Not Found", func(t *testing.T) {
		_, err := repo.GetByID(9999)
		if err == nil {
			t.Fatal("Expected error for non-existent user, got nil")
		}
	})
}

func TestGetByEmail(t *testing.T) {
	repo := NewUserRepository(testDB)

	t.Run("User Exists", func(t *testing.T) {
		user, err := repo.GetByEmail("bob@example.com")
		if err != nil {
			t.Fatalf("Expected no error, got: %v", err)
		}

		if user.Name != "Bob Johnson" {
			t.Errorf("Expected name 'Bob Johnson', got: %s", user.Name)
		}
	})

	t.Run("User Not Found", func(t *testing.T) {
		_, err := repo.GetByEmail("nonexistent@example.com")
		if err == nil {
			t.Fatal("Expected error for non-existent email, got nil")
		}
	})
}

func TestCreate(t *testing.T) {
	repo := NewUserRepository(testDB)

	t.Run("Create New User", func(t *testing.T) {
		user, err := repo.Create("charlie@example.com", "Charlie Brown")
		if err != nil {
			t.Fatalf("Failed to create user: %v", err)
		}

		if user.ID == 0 {
			t.Error("Expected non-zero ID for created user")
		}

		if user.Email != "charlie@example.com" {
			t.Errorf("Expected email 'charlie@example.com', got: %s", user.Email)
		}

		if user.CreatedAt.IsZero() {
			t.Error("Expected non-zero created_at timestamp")
		}

		defer repo.Delete(user.ID)
	})

	t.Run("Create Duplicate Email", func(t *testing.T) {
		_, err := repo.Create("alice@example.com", "Another Alice")
		if err == nil {
			t.Fatal("Expected error when creating user with duplicate email")
		}
	})
}

func TestUpdate(t *testing.T) {
	repo := NewUserRepository(testDB)

	t.Run("Update Existing User", func(t *testing.T) {
		user, err := repo.Create("david@example.com", "David Davis")
		if err != nil {
			t.Fatalf("Failed to create test user: %v", err)
		}
		defer repo.Delete(user.ID)

		err = repo.Update(user.ID, "david.updated@example.com", "David Updated")
		if err != nil {
			t.Fatalf("Failed to update user: %v", err)
		}

		updatedUser, err := repo.GetByID(user.ID)
		if err != nil {
			t.Fatalf("Failed to retrieve updated user: %v", err)
		}

		if updatedUser.Email != "david.updated@example.com" {
			t.Errorf("Expected email 'david.updated@example.com', got: %s", updatedUser.Email)
		}

		if updatedUser.Name != "David Updated" {
			t.Errorf("Expected name 'David Updated', got: %s", updatedUser.Name)
		}
	})

	t.Run("Update Non-Existent User", func(t *testing.T) {
		err := repo.Update(9999, "nobody@example.com", "Nobody")
		if err == nil {
			t.Fatal("Expected error when updating non-existent user")
		}
	})
}

func TestDelete(t *testing.T) {
	repo := NewUserRepository(testDB)

	t.Run("Delete Existing User", func(t *testing.T) {
		user, err := repo.Create("temp@example.com", "Temporary User")
		if err != nil {
			t.Fatalf("Failed to create test user: %v", err)
		}

		err = repo.Delete(user.ID)
		if err != nil {
			t.Fatalf("Failed to delete user: %v", err)
		}

		_, err = repo.GetByID(user.ID)
		if err == nil {
			t.Fatal("Expected error when retrieving deleted user")
		}
	})

	t.Run("Delete Non-Existent User", func(t *testing.T) {
		err := repo.Delete(9999)
		if err == nil {
			t.Fatal("Expected error when deleting non-existent user")
		}
	})
}

func TestList(t *testing.T) {
	repo := NewUserRepository(testDB)

	users, err := repo.List()
	if err != nil {
		t.Fatalf("Failed to list users: %v", err)
	}

	if len(users) < 2 {
		t.Errorf("Expected at least 2 users, got: %d", len(users))
	}

	if users[0].Email != "alice@example.com" {
		t.Errorf("Expected first user email 'alice@example.com', got: %s", users[0].Email)
	}
}

func TestFindByNamePattern(t *testing.T) {
	repo := NewUserRepository(testDB)

	t.Run("Pattern Matches Multiple Users", func(t *testing.T) {
		// Create test users with similar patterns
		user1, _ := repo.Create("smith1@example.com", "John Smith")
		user2, _ := repo.Create("smith2@example.com", "Jane Smith")
		defer repo.Delete(user1.ID)
		defer repo.Delete(user2.ID)

		users, err := repo.FindByNamePattern("%Smith%")
		if err != nil {
			t.Fatalf("Failed to find users by pattern: %v", err)
		}

		if len(users) < 2 {
			t.Errorf("Expected at least 2 users with 'Smith', got: %d", len(users))
		}
	})

	t.Run("Pattern Matches No Users", func(t *testing.T) {
		users, err := repo.FindByNamePattern("%XYZ%")
		if err != nil {
			t.Fatalf("Failed to find users by pattern: %v", err)
		}

		if len(users) != 0 {
			t.Errorf("Expected 0 users with 'XYZ', got: %d", len(users))
		}
	})

	t.Run("Case Insensitive Pattern", func(t *testing.T) {
		users, err := repo.FindByNamePattern("%alice%")
		if err != nil {
			t.Fatalf("Failed to find users by pattern: %v", err)
		}

		if len(users) == 0 {
			t.Error("Expected case-insensitive match for 'alice'")
		}
	})
}

func TestCountUsers(t *testing.T) {
	repo := NewUserRepository(testDB)

	initialCount, err := repo.CountUsers()
	if err != nil {
		t.Fatalf("Failed to count users: %v", err)
	}

	// Create a new user
	user, err := repo.Create("count@example.com", "Count User")
	if err != nil {
		t.Fatalf("Failed to create user: %v", err)
	}
	defer repo.Delete(user.ID)

	newCount, err := repo.CountUsers()
	if err != nil {
		t.Fatalf("Failed to count users: %v", err)
	}

	if newCount != initialCount+1 {
		t.Errorf("Expected count %d, got: %d", initialCount+1, newCount)
	}
}

func TestGetRecentUsers(t *testing.T) {
	repo := NewUserRepository(testDB)

	t.Run("Recent Users Within Days", func(t *testing.T) {
		// Create a new user (will have current timestamp)
		user, err := repo.Create("recent@example.com", "Recent User")
		if err != nil {
			t.Fatalf("Failed to create user: %v", err)
		}
		defer repo.Delete(user.ID)

		// Get users from last 7 days
		users, err := repo.GetRecentUsers(7)
		if err != nil {
			t.Fatalf("Failed to get recent users: %v", err)
		}

		found := false
		for _, u := range users {
			if u.ID == user.ID {
				found = true
				break
			}
		}

		if !found {
			t.Error("Expected to find recently created user")
		}
	})

	t.Run("No Recent Users", func(t *testing.T) {
		// Query for users in last 0 days (should return empty or very recent)
		users, err := repo.GetRecentUsers(0)
		if err != nil {
			t.Fatalf("Failed to get recent users: %v", err)
		}

		// This test verifies the query runs without error
		_ = users
	})
}

func TestBatchCreate(t *testing.T) {
	repo := NewUserRepository(testDB)

	t.Run("Successful Batch Create", func(t *testing.T) {
		users := []struct{ Email, Name string }{
			{"batch1@example.com", "Batch User 1"},
			{"batch2@example.com", "Batch User 2"},
			{"batch3@example.com", "Batch User 3"},
		}

		err := repo.BatchCreate(users)
		if err != nil {
			t.Fatalf("Failed to batch create users: %v", err)
		}

		// Verify all users were created
		for _, u := range users {
			user, err := repo.GetByEmail(u.Email)
			if err != nil {
				t.Errorf("Failed to find user %s: %v", u.Email, err)
			}
			defer repo.Delete(user.ID)
		}
	})

	t.Run("Batch Create with Duplicate Email Rolls Back", func(t *testing.T) {
		countBefore, _ := repo.CountUsers()

		users := []struct{ Email, Name string }{
			{"unique1@example.com", "Unique 1"},
			{"alice@example.com", "Duplicate Alice"}, // Duplicate!
			{"unique2@example.com", "Unique 2"},
		}

		err := repo.BatchCreate(users)
		if err == nil {
			t.Fatal("Expected error for duplicate email in batch")
		}

		countAfter, _ := repo.CountUsers()
		if countAfter != countBefore {
			t.Error("Expected transaction rollback, but count changed")
		}

		// Verify none of the unique users were created
		_, err = repo.GetByEmail("unique1@example.com")
		if err == nil {
			t.Error("Expected unique1 to not exist after rollback")
		}
	})
}

func TestTransactionRollback(t *testing.T) {
	countBefore, _ := NewUserRepository(testDB).CountUsers()

	tx, err := testDB.Begin()
	if err != nil {
		t.Fatal(err)
	}

	// Create user in transaction
	_, err = tx.Exec("INSERT INTO users (email, name) VALUES ($1, $2)",
		"tx@example.com", "TX User")
	if err != nil {
		t.Fatal(err)
	}

	// Rollback transaction
	tx.Rollback()

	// Verify count is unchanged
	repo := NewUserRepository(testDB)
	countAfter, _ := repo.CountUsers()
	if countAfter != countBefore {
		t.Error("Transaction was not rolled back properly")
	}

	// Verify user doesn't exist
	_, err = repo.GetByEmail("tx@example.com")
	if err == nil {
		t.Error("Expected user to not exist after rollback")
	}
}

func TestTransferUserData(t *testing.T) {
	repo := NewUserRepository(testDB)

	t.Run("Successful Transfer", func(t *testing.T) {
		// Create source and target users
		source, _ := repo.Create("source@example.com", "Source User")
		target, _ := repo.Create("target@example.com", "Target User")
		defer repo.Delete(source.ID)
		defer repo.Delete(target.ID)

		// Transfer data
		err := repo.TransferUserData(source.ID, target.ID)
		if err != nil {
			t.Fatalf("Failed to transfer data: %v", err)
		}

		// Verify target has source's name
		targetUser, _ := repo.GetByID(target.ID)
		if targetUser.Name != "Source User" {
			t.Errorf("Expected target name 'Source User', got: %s", targetUser.Name)
		}
	})

	t.Run("Transfer with Invalid Source ID", func(t *testing.T) {
		target, _ := repo.Create("target2@example.com", "Target 2")
		defer repo.Delete(target.ID)

		err := repo.TransferUserData(9999, target.ID)
		if err == nil {
			t.Fatal("Expected error for invalid source ID")
		}
	})
}

func TestConcurrentWrites(t *testing.T) {
	repo := NewUserRepository(testDB)

	// Create a user
	user, _ := repo.Create("concurrent@example.com", "Concurrent User")
	defer repo.Delete(user.ID)

	// Simulate concurrent updates
	done := make(chan bool, 2)

	go func() {
		for i := 0; i < 10; i++ {
			repo.Update(user.ID, "concurrent@example.com", fmt.Sprintf("Name %d", i))
		}
		done <- true
	}()

	go func() {
		for i := 0; i < 10; i++ {
			repo.Update(user.ID, "concurrent@example.com", fmt.Sprintf("Other %d", i))
		}
		done <- true
	}()

	<-done
	<-done

	// Verify user still exists and is valid
	finalUser, err := repo.GetByID(user.ID)
	if err != nil {
		t.Fatalf("User corrupted after concurrent writes: %v", err)
	}

	if finalUser.Email != "concurrent@example.com" {
		t.Error("User email changed unexpectedly")
	}
}

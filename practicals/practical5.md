# Practical 5: Integration Testing with TestContainers for Database Testing

## Table of Contents

1. [Introduction to Integration Testing](#introduction)
2. [Prerequisites](#prerequisites)
3. [Understanding TestContainers](#understanding-testcontainers)
4. [Setting Up Your Project](#setup-project)
5. [Writing Your First TestContainer Test](#first-test)
6. [Testing Database Operations](#database-operations)
7. [Advanced TestContainers Patterns](#advanced-patterns)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)
10. [Hands-on Exercises](#exercises)

## 1. Introduction to Integration Testing {#introduction}

### What is Integration Testing?

Integration testing is a level of software testing where individual units or components are combined and tested as a group. Unlike unit tests that test isolated pieces of code, integration tests verify that different parts of your system work together correctly.

**Key Characteristics:**
- Tests multiple components together
- Verifies interactions between components
- Uses real dependencies (databases, message queues, etc.)
- Slower than unit tests but more realistic
- Catches integration issues early

### What is TestContainers?

TestContainers is a library that provides lightweight, throwaway instances of databases, message brokers, web browsers, or anything that can run in a Docker container. It makes integration testing with real dependencies simple and reliable.

**TestContainers Benefits:**
- **Real Dependencies**: Test against actual databases, not mocks
- **Isolation**: Each test gets a fresh container
- **Portability**: Works on any machine with Docker
- **Clean State**: Containers are destroyed after tests
- **CI/CD Friendly**: Perfect for automated testing pipelines

### Why TestContainers for Database Testing?

Traditional approaches to database testing have problems:

| Approach | Problems |
|----------|----------|
| **In-Memory Databases (H2, SQLite)** | Different SQL dialects, missing features, not production-like |
| **Shared Test Database** | Flaky tests due to shared state, cleanup issues, slow |
| **Mocked Database** | Doesn't test actual SQL, misses database-specific bugs |
| **TestContainers** | ✅ Real database, isolated, production-like, reliable |

## 2. Prerequisites {#prerequisites}

Before starting this practical, ensure you have:

- [ ] Go installed (version 1.19 or higher)
- [ ] Docker Desktop installed and running
- [ ] Basic understanding of Go and SQL
- [ ] Familiarity with unit testing in Go (see Practical 2)
- [ ] A code editor (VS Code, GoLand, etc.)

### Verify Your Environment

```bash
# Check Go version
go version
# Output: go version go1.21.0 darwin/arm64 (or similar)

# Check Docker is running
docker ps
# Should show running containers (or empty list if none running)

# Check Docker version
docker --version
# Output: Docker version 24.0.0, build abc1234
```

### Project Setup

Create a new Go project for this practical:

```bash
# Create project directory
mkdir testcontainers-demo
cd testcontainers-demo

# Initialize Go module
go mod init testcontainers-demo

# Install required dependencies
go get github.com/testcontainers/testcontainers-go
go get github.com/testcontainers/testcontainers-go/modules/postgres
go get github.com/lib/pq
```

## 3. Understanding TestContainers {#understanding-testcontainers}

### How TestContainers Works

```
Test Lifecycle with TestContainers:
┌─────────────────────────────────────────────────────┐
│  1. Test Starts                                     │
│     └─> TestContainers pulls Docker image          │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  2. Container Starts                                │
│     └─> Database initializes                       │
│     └─> Schema/migrations run (if configured)      │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  3. Test Runs                                       │
│     └─> Test code connects to container            │
│     └─> Executes database operations               │
│     └─> Verifies results                           │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  4. Cleanup                                         │
│     └─> Container stops                            │
│     └─> Container is removed                       │
│     └─> Data is destroyed                          │
└─────────────────────────────────────────────────────┘
```

### TestContainers Architecture

```go
// Simplified architecture
Container
├── Image (e.g., postgres:15)
├── Environment Variables
├── Port Mappings (random host port → container port)
├── Wait Strategies (ensure container is ready)
└── Lifecycle Hooks
    ├── Start
    ├── Ready
    └── Terminate
```

### Key Concepts

1. **Container Lifecycle**
   - Containers are created at test start
   - Automatically destroyed after test completes
   - Each test can have its own container (isolation)

2. **Wait Strategies**
   - Ensure container is ready before test runs
   - Examples: wait for log message, wait for port, wait for HTTP endpoint

3. **Port Mapping**
   - Container exposes service on random host port
   - Prevents port conflicts
   - Test retrieves actual port dynamically

4. **Network Isolation**
   - Each container runs in isolated network
   - Tests cannot interfere with each other

## 4. Setting Up Your Project {#setup-project}

### Project Structure

Create the following structure:

```
testcontainers-demo/
├── go.mod
├── go.sum
├── models/
│   └── user.go          # Data models
├── repository/
│   └── user_repository.go    # Database access layer
│   └── user_repository_test.go  # Integration tests
├── migrations/
│   └── init.sql         # Database schema
└── README.md
```

### Step 4.1: Create the Data Model

Create `models/user.go`:

```go
// models/user.go
package models

import "time"

// User represents a user in our system
type User struct {
	ID        int       `json:"id"`
	Email     string    `json:"email"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
}
```

### Step 4.2: Create Database Schema

Create `migrations/init.sql`:

```sql
-- migrations/init.sql
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert some test data
INSERT INTO users (email, name) VALUES
    ('alice@example.com', 'Alice Smith'),
    ('bob@example.com', 'Bob Johnson');
```

### Step 4.3: Create Repository Layer

Create `repository/user_repository.go`:

```go
// repository/user_repository.go
package repository

import (
	"database/sql"
	"fmt"
	"testcontainers-demo/models"
)

// UserRepository handles database operations for users
type UserRepository struct {
	db *sql.DB
}

// NewUserRepository creates a new user repository
func NewUserRepository(db *sql.DB) *UserRepository {
	return &UserRepository{db: db}
}

// GetByID retrieves a user by their ID
func (r *UserRepository) GetByID(id int) (*models.User, error) {
	query := "SELECT id, email, name, created_at FROM users WHERE id = $1"

	var user models.User
	err := r.db.QueryRow(query, id).Scan(
		&user.ID,
		&user.Email,
		&user.Name,
		&user.CreatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return &user, nil
}

// GetByEmail retrieves a user by their email
func (r *UserRepository) GetByEmail(email string) (*models.User, error) {
	query := "SELECT id, email, name, created_at FROM users WHERE email = $1"

	var user models.User
	err := r.db.QueryRow(query, email).Scan(
		&user.ID,
		&user.Email,
		&user.Name,
		&user.CreatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return &user, nil
}

// Create inserts a new user
func (r *UserRepository) Create(email, name string) (*models.User, error) {
	query := `
		INSERT INTO users (email, name)
		VALUES ($1, $2)
		RETURNING id, email, name, created_at
	`

	var user models.User
	err := r.db.QueryRow(query, email, name).Scan(
		&user.ID,
		&user.Email,
		&user.Name,
		&user.CreatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return &user, nil
}

// Update modifies an existing user
func (r *UserRepository) Update(id int, email, name string) error {
	query := "UPDATE users SET email = $1, name = $2 WHERE id = $3"

	result, err := r.db.Exec(query, email, name, id)
	if err != nil {
		return fmt.Errorf("failed to update user: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("user not found")
	}

	return nil
}

// Delete removes a user
func (r *UserRepository) Delete(id int) error {
	query := "DELETE FROM users WHERE id = $1"

	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete user: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("user not found")
	}

	return nil
}

// List retrieves all users
func (r *UserRepository) List() ([]models.User, error) {
	query := "SELECT id, email, name, created_at FROM users ORDER BY id"

	rows, err := r.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to list users: %w", err)
	}
	defer rows.Close()

	var users []models.User
	for rows.Next() {
		var user models.User
		err := rows.Scan(&user.ID, &user.Email, &user.Name, &user.CreatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan user: %w", err)
		}
		users = append(users, user)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating users: %w", err)
	}

	return users, nil
}
```

## 5. Writing Your First TestContainer Test {#first-test}

Now comes the exciting part - writing integration tests using TestContainers!

Create `repository/user_repository_test.go`:

```go
// repository/user_repository_test.go
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

// Global test database connection
var testDB *sql.DB

// TestMain sets up the test environment
// This runs ONCE before all tests in this package
func TestMain(m *testing.M) {
	ctx := context.Background()

	// Create a PostgreSQL container
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

	// Ensure container is terminated at the end
	defer func() {
		if err := postgresContainer.Terminate(ctx); err != nil {
			fmt.Fprintf(os.Stderr, "Failed to terminate container: %v\n", err)
		}
	}()

	// Get connection string
	connStr, err := postgresContainer.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to get connection string: %v\n", err)
		os.Exit(1)
	}

	// Connect to the database
	testDB, err = sql.Open("postgres", connStr)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to connect to database: %v\n", err)
		os.Exit(1)
	}

	// Verify connection
	if err = testDB.Ping(); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to ping database: %v\n", err)
		os.Exit(1)
	}

	// Run tests
	code := m.Run()

	// Cleanup
	testDB.Close()
	os.Exit(code)
}

// TestGetByID tests retrieving a user by ID
func TestGetByID(t *testing.T) {
	repo := NewUserRepository(testDB)

	// Test case 1: User exists (from init.sql)
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

	// Test case 2: User does not exist
	t.Run("User Not Found", func(t *testing.T) {
		_, err := repo.GetByID(9999)
		if err == nil {
			t.Fatal("Expected error for non-existent user, got nil")
		}
	})
}

// TestGetByEmail tests retrieving a user by email
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
```

### Running Your First Test

```bash
# Run all tests
go test ./repository -v

# Expected output:
# === RUN   TestGetByID
# === RUN   TestGetByID/User_Exists
# === RUN   TestGetByID/User_Not_Found
# --- PASS: TestGetByID (0.00s)
#     --- PASS: TestGetByID/User_Exists (0.00s)
#     --- PASS: TestGetByID/User_Not_Found (0.00s)
# === RUN   TestGetByEmail
# ...
# PASS
```

### Understanding What Just Happened

1. **TestMain** executed first, setting up a PostgreSQL container
2. The container downloaded the `postgres:15-alpine` image (if not cached)
3. The container started and initialized the database
4. The `init.sql` script ran, creating tables and inserting test data
5. Each test function ran, querying the real PostgreSQL database
6. After all tests completed, the container was destroyed

## 6. Testing Database Operations {#database-operations}

Let's write comprehensive tests for all CRUD operations.

Add these tests to `repository/user_repository_test.go`:

```go
// TestCreate tests user creation
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

		// Cleanup: delete the created user
		defer repo.Delete(user.ID)
	})

	t.Run("Create Duplicate Email", func(t *testing.T) {
		// Try to create user with existing email (from init.sql)
		_, err := repo.Create("alice@example.com", "Another Alice")
		if err == nil {
			t.Fatal("Expected error when creating user with duplicate email")
		}
	})
}

// TestUpdate tests user updates
func TestUpdate(t *testing.T) {
	repo := NewUserRepository(testDB)

	t.Run("Update Existing User", func(t *testing.T) {
		// First, create a user to update
		user, err := repo.Create("david@example.com", "David Davis")
		if err != nil {
			t.Fatalf("Failed to create test user: %v", err)
		}
		defer repo.Delete(user.ID)

		// Update the user
		err = repo.Update(user.ID, "david.updated@example.com", "David Updated")
		if err != nil {
			t.Fatalf("Failed to update user: %v", err)
		}

		// Verify the update
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

// TestDelete tests user deletion
func TestDelete(t *testing.T) {
	repo := NewUserRepository(testDB)

	t.Run("Delete Existing User", func(t *testing.T) {
		// Create a user to delete
		user, err := repo.Create("temp@example.com", "Temporary User")
		if err != nil {
			t.Fatalf("Failed to create test user: %v", err)
		}

		// Delete the user
		err = repo.Delete(user.ID)
		if err != nil {
			t.Fatalf("Failed to delete user: %v", err)
		}

		// Verify deletion
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

// TestList tests listing all users
func TestList(t *testing.T) {
	repo := NewUserRepository(testDB)

	users, err := repo.List()
	if err != nil {
		t.Fatalf("Failed to list users: %v", err)
	}

	// Should have at least 2 users from init.sql
	if len(users) < 2 {
		t.Errorf("Expected at least 2 users, got: %d", len(users))
	}

	// Verify first user
	if users[0].Email != "alice@example.com" {
		t.Errorf("Expected first user email 'alice@example.com', got: %s", users[0].Email)
	}
}
```

### Test Isolation Strategies

One challenge with integration tests is maintaining test isolation. Here are strategies:

#### Strategy 1: Cleanup in Each Test (shown above)

```go
func TestSomething(t *testing.T) {
	// Create test data
	user, _ := repo.Create("test@example.com", "Test User")

	// Always cleanup, even if test fails
	defer repo.Delete(user.ID)

	// Run test logic
	// ...
}
```

#### Strategy 2: Transaction Rollback

```go
func TestWithTransaction(t *testing.T) {
	// Start transaction
	tx, err := testDB.Begin()
	if err != nil {
		t.Fatal(err)
	}

	// Always rollback
	defer tx.Rollback()

	// Create repo with transaction
	repo := NewUserRepository(tx) // Modify repo to accept sql.DB or sql.Tx

	// Test operations (will be rolled back)
	user, _ := repo.Create("test@example.com", "Test")
	// ... test logic
}
```

#### Strategy 3: Fresh Container Per Test

```go
func TestWithFreshContainer(t *testing.T) {
	ctx := context.Background()

	// Start container
	container, _ := postgres.RunContainer(ctx, /* ... */)
	defer container.Terminate(ctx)

	// Connect
	connStr, _ := container.ConnectionString(ctx, "sslmode=disable")
	db, _ := sql.Open("postgres", connStr)
	defer db.Close()

	// Run test with fresh database
	repo := NewUserRepository(db)
	// ... test logic
}
```

## 7. Advanced TestContainers Patterns {#advanced-patterns}

### Pattern 1: Custom Wait Strategies

```go
// Wait for specific log pattern
container, err := postgres.RunContainer(ctx,
	testcontainers.WithImage("postgres:15"),
	testcontainers.WithWaitStrategy(
		wait.ForLog("database system is ready").
			WithOccurrence(2).
			WithStartupTimeout(30*time.Second),
	),
)
```

### Pattern 2: Network Configuration

```go
// Create custom network for multiple containers
network, err := testcontainers.GenericNetwork(ctx, testcontainers.GenericNetworkRequest{
	NetworkRequest: testcontainers.NetworkRequest{
		Name: "test-network",
	},
})

// Start containers on the same network
pgContainer, _ := postgres.RunContainer(ctx,
	testcontainers.WithNetwork(network),
	// ...
)

appContainer, _ := /* your app container */
	testcontainers.WithNetwork(network),
	// ...
)
```

### Pattern 3: Environment Variables

```go
container, err := postgres.RunContainer(ctx,
	testcontainers.WithImage("postgres:15"),
	testcontainers.WithEnv(map[string]string{
		"POSTGRES_SHARED_BUFFERS": "256MB",
		"POSTGRES_MAX_CONNECTIONS": "200",
	}),
)
```

### Pattern 4: Volume Mounts

```go
container, err := postgres.RunContainer(ctx,
	testcontainers.WithImage("postgres:15"),
	testcontainers.WithBindMounts(map[string]string{
		"/path/on/host/data": "/var/lib/postgresql/data",
	}),
)
```

### Pattern 5: Reusable Containers

```go
// Reuse container across tests (faster but less isolated)
container, err := postgres.RunContainer(ctx,
	testcontainers.WithImage("postgres:15"),
	testcontainers.WithLabel("reuse", "true"),
)
```

## 8. Best Practices {#best-practices}

### Testing Best Practices

1. **Use TestMain for Setup/Teardown**
   ```go
   func TestMain(m *testing.M) {
       // Global setup
       setupContainer()

       // Run tests
       code := m.Run()

       // Global teardown
       teardownContainer()

       os.Exit(code)
   }
   ```

2. **Table-Driven Tests for Multiple Scenarios**
   ```go
   func TestCreateUser_TableDriven(t *testing.T) {
       testCases := []struct {
           name        string
           email       string
           userName    string
           expectError bool
       }{
           {"Valid User", "valid@example.com", "Valid User", false},
           {"Duplicate Email", "alice@example.com", "Duplicate", true},
           {"Empty Email", "", "No Email", true},
       }

       repo := NewUserRepository(testDB)

       for _, tc := range testCases {
           t.Run(tc.name, func(t *testing.T) {
               _, err := repo.Create(tc.email, tc.userName)

               if tc.expectError && err == nil {
                   t.Error("Expected error but got nil")
               }

               if !tc.expectError && err != nil {
                   t.Errorf("Expected no error but got: %v", err)
               }
           })
       }
   }
   ```

3. **Test Cleanup**
   ```go
   func TestWithCleanup(t *testing.T) {
       user, _ := repo.Create("cleanup@example.com", "Cleanup User")

       // t.Cleanup runs after test, even if test fails
       t.Cleanup(func() {
           repo.Delete(user.ID)
       })

       // Test logic...
   }
   ```

### Performance Best Practices

1. **Reuse Containers When Possible**
   - Start one container for all tests in a package
   - Use transactions for isolation
   - Reset state between tests

2. **Parallel Test Execution**
   ```go
   func TestConcurrent(t *testing.T) {
       t.Parallel() // Run in parallel with other parallel tests

       // Each parallel test needs its own database connection
       // or use connection pooling
   }
   ```

3. **Use Alpine Images**
   ```go
   postgres.RunContainer(ctx,
       testcontainers.WithImage("postgres:15-alpine"), // Smaller, faster
   )
   ```

4. **Cache Docker Images**
   - Docker automatically caches pulled images
   - First run is slow, subsequent runs are fast
   - Share Docker cache in CI/CD

### CI/CD Best Practices

1. **Ensure Docker is Available**
   ```yaml
   # GitHub Actions example
   jobs:
     test:
       runs-on: ubuntu-latest
       services:
         docker:
           image: docker:latest
       steps:
         - uses: actions/checkout@v4
         - name: Run integration tests
           run: go test ./... -v
   ```

2. **Set Timeouts**
   ```go
   ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
   defer cancel()

   container, err := postgres.RunContainer(ctx, /* ... */)
   ```

3. **Clean Up Resources**
   ```go
   defer func() {
       if err := container.Terminate(context.Background()); err != nil {
           t.Logf("Failed to terminate container: %v", err)
       }
   }()
   ```

## 9. Troubleshooting {#troubleshooting}

### Common Issues and Solutions

#### Issue 1: "Cannot connect to Docker daemon"

**Problem**: TestContainers cannot find Docker

**Solutions**:
```bash
# 1. Ensure Docker Desktop is running
# On macOS: Check Docker icon in menu bar

# 2. Verify Docker socket
ls -la /var/run/docker.sock

# 3. Set Docker host environment variable (if needed)
export DOCKER_HOST=unix:///var/run/docker.sock

# 4. Test Docker connection
docker ps
```

#### Issue 2: "Container startup timeout"

**Problem**: Container takes too long to start

**Solutions**:
```go
// Increase timeout
wait.ForLog("ready").
    WithStartupTimeout(60*time.Second) // Increase from default

// Use simpler wait strategy
wait.ForListeningPort("5432/tcp")

// Check Docker resources
// Docker Desktop → Settings → Resources → Increase CPU/Memory
```

#### Issue 3: "Port already in use"

**Problem**: Container tries to bind to used port

**Solution**:
```go
// TestContainers automatically assigns random ports
// Don't specify host port, let it auto-assign

// Get the actual assigned port:
host, err := container.Host(ctx)
port, err := container.MappedPort(ctx, "5432/tcp")
connStr := fmt.Sprintf("postgres://user:pass@%s:%s/db", host, port.Port())
```

#### Issue 4: "Image pull failed"

**Problem**: Cannot download Docker image

**Solutions**:
```bash
# 1. Check internet connection

# 2. Manually pull image first
docker pull postgres:15-alpine

# 3. Use locally available image
# Check available images:
docker images

# 4. Configure Docker registry mirror (if in restricted network)
```

#### Issue 5: "Test data persists between tests"

**Problem**: Tests interfere with each other

**Solutions**:
```go
// Strategy 1: Use transactions with rollback
tx, _ := db.Begin()
defer tx.Rollback()

// Strategy 2: Truncate tables before each test
func resetDatabase(t *testing.T, db *sql.DB) {
    t.Helper()
    _, err := db.Exec("TRUNCATE TABLE users CASCADE")
    if err != nil {
        t.Fatalf("Failed to reset database: %v", err)
    }
}

// Strategy 3: Start fresh container per test
func TestWithFreshDB(t *testing.T) {
    container, db := setupFreshContainer(t)
    defer container.Terminate(context.Background())
    // Test with clean database
}
```

#### Issue 6: "Tests slow in CI/CD"

**Problem**: Container startup is slow in pipeline

**Solutions**:
```yaml
# 1. Cache Docker layers
- name: Cache Docker layers
  uses: actions/cache@v3
  with:
    path: /var/lib/docker
    key: docker-${{ hashFiles('**/go.sum') }}

# 2. Use smaller images
# postgres:15-alpine instead of postgres:15

# 3. Pull image before tests
- name: Pre-pull image
  run: docker pull postgres:15-alpine

# 4. Reduce test parallelism if memory-constrained
- name: Run tests
  run: go test -p 1 ./... # Run tests sequentially
```

## 10. Hands-on Exercises {#exercises}

### Exercise 1: Basic TestContainers Setup (25 minutes)

**Objective**: Set up your first TestContainers integration test

**Tasks**:
1. Create the project structure
2. Implement the User model
3. Create the database schema (`init.sql`)
4. Write the repository layer
5. Write basic integration tests for `GetByID` and `GetByEmail`

**Expected Outcome**:
- Tests pass successfully
- Container starts and stops automatically
- You can see container in Docker while tests run

**Verification**:
```bash
# Run tests
go test ./repository -v

# While tests run, check containers (in another terminal)
docker ps

# After tests complete, verify container is gone
docker ps -a
```

### Exercise 2: Complete CRUD Testing (30 minutes)

**Objective**: Write comprehensive tests for all CRUD operations

**Tasks**:
1. Implement tests for `Create()` operation
   - Test successful creation
   - Test duplicate email constraint
   - Verify auto-generated ID
   - Check created_at timestamp

2. Implement tests for `Update()` operation
   - Test successful update
   - Test updating non-existent user
   - Verify changes persist

3. Implement tests for `Delete()` operation
   - Test successful deletion
   - Test deleting non-existent user
   - Verify user is gone after deletion

4. Implement tests for `List()` operation
   - Test listing all users
   - Verify order
   - Check count

**Expected Outcome**:
- All CRUD operations tested
- Edge cases covered
- Tests are isolated (don't interfere with each other)

### Exercise 3: Advanced Queries (35 minutes)

**Objective**: Test complex database queries

**Tasks**:
1. Add new methods to `UserRepository`:
   ```go
   // FindByNamePattern finds users whose name matches a pattern
   func (r *UserRepository) FindByNamePattern(pattern string) ([]models.User, error)

   // CountUsers returns total number of users
   func (r *UserRepository) CountUsers() (int, error)

   // GetRecentUsers returns users created in the last N days
   func (r *UserRepository) GetRecentUsers(days int) ([]models.User, error)
   ```

2. Implement these methods with SQL queries:
   ```sql
   -- FindByNamePattern
   SELECT * FROM users WHERE name ILIKE $1

   -- CountUsers
   SELECT COUNT(*) FROM users

   -- GetRecentUsers
   SELECT * FROM users
   WHERE created_at >= NOW() - INTERVAL '$1 days'
   ORDER BY created_at DESC
   ```

3. Write integration tests for each method:
   - Create test data with various patterns
   - Test pattern matching (e.g., "% Smith%")
   - Test empty results
   - Test date filtering

**Expected Outcome**:
- Complex SQL queries tested against real database
- Pattern matching works correctly
- Date filtering accurate

### Exercise 4: Transaction Testing (30 minutes)

**Objective**: Test database transactions

**Tasks**:
1. Add a transaction-aware method:
   ```go
   // TransferUsers simulates a transaction involving multiple operations
   func (r *UserRepository) TransferUserData(fromID, toID int) error {
       // Start transaction
       tx, err := r.db.Begin()
       if err != nil {
           return err
       }

       // Multiple operations...

       // Commit or rollback
       return tx.Commit()
   }
   ```

2. Write tests that verify:
   - Successful transaction commits
   - Failed transaction rolls back
   - Data consistency after rollback
   - Concurrent transaction handling

**Example Test**:
```go
func TestTransactionRollback(t *testing.T) {
	repo := NewUserRepository(testDB)

	// Count users before
	countBefore, _ := repo.CountUsers()

	// Start a transaction that will fail
	tx, _ := testDB.Begin()

	// Create user in transaction
	_, err := tx.Exec("INSERT INTO users (email, name) VALUES ($1, $2)",
		"tx@example.com", "TX User")
	if err != nil {
		t.Fatal(err)
	}

	// Rollback transaction
	tx.Rollback()

	// Verify count is unchanged
	countAfter, _ := repo.CountUsers()
	if countAfter != countBefore {
		t.Error("Transaction was not rolled back properly")
	}
}
```

**Expected Outcome**:
- Understanding of transaction isolation
- Proper rollback behavior
- Data consistency maintained

### Exercise 5: Multi-Container Testing (40 minutes)

**Objective**: Test with multiple interconnected containers

**Tasks**:
1. Add Redis for caching:
   ```bash
   go get github.com/testcontainers/testcontainers-go/modules/redis
   ```

2. Create a cached repository:
   ```go
   type CachedUserRepository struct {
       db    *sql.DB
       cache *redis.Client
   }

   func (r *CachedUserRepository) GetByIDCached(id int) (*models.User, error) {
       // Try cache first
       cached, err := r.cache.Get(ctx, fmt.Sprintf("user:%d", id)).Result()
       if err == nil {
           var user models.User
           json.Unmarshal([]byte(cached), &user)
           return &user, nil
       }

       // Cache miss - query database
       user, err := r.getFromDB(id)
       if err != nil {
           return nil, err
       }

       // Store in cache
       data, _ := json.Marshal(user)
       r.cache.Set(ctx, fmt.Sprintf("user:%d", id), data, 5*time.Minute)

       return user, nil
   }
   ```

3. Write tests that verify:
   - Cache hit returns cached data
   - Cache miss queries database
   - Cache is populated after database query
   - Both containers work together

**Test Setup**:
```go
func TestMain(m *testing.M) {
	ctx := context.Background()

	// Start PostgreSQL
	pgContainer, _ := postgres.RunContainer(ctx, /* ... */)

	// Start Redis
	redisContainer, _ := redis.RunContainer(ctx,
		testcontainers.WithImage("redis:7-alpine"),
	)

	// Setup connections
	// ...

	// Run tests
	code := m.Run()

	// Cleanup
	pgContainer.Terminate(ctx)
	redisContainer.Terminate(ctx)

	os.Exit(code)
}
```

**Expected Outcome**:
- Multiple containers running simultaneously
- Containers communicate correctly
- Cache behavior verified
- Understanding of multi-service testing

## Conclusion

In this practical, you've learned:

1. ✅ What integration testing is and why it matters
2. ✅ How TestContainers simplifies database testing
3. ✅ Setting up PostgreSQL containers for tests
4. ✅ Writing integration tests for CRUD operations
5. ✅ Advanced patterns and best practices
6. ✅ Troubleshooting common issues

### Key Takeaways

- **Real Databases**: Integration tests with TestContainers use real databases, catching SQL dialect issues and database-specific bugs
- **Isolation**: Each test can have a clean database state
- **CI/CD Ready**: Works seamlessly in automated pipelines
- **Developer Friendly**: Simple API, minimal boilerplate
- **Production-Like**: Tests run against the same database engine as production

### Next Steps

1. **Apply to Your Projects**: Add integration tests to existing projects
2. **Explore Other Modules**: TestContainers supports MySQL, MongoDB, Kafka, etc.
3. **Performance Tuning**: Optimize test suite for faster execution
4. **Advanced Scenarios**: Test database migrations, stored procedures, triggers
5. **Continuous Learning**: Follow TestContainers blog and updates

### Additional Resources

- [TestContainers Go Documentation](https://golang.testcontainers.org/)
- [TestContainers Modules](https://golang.testcontainers.org/modules/)
- [Integration Testing Best Practices](https://martinfowler.com/bliki/IntegrationTest.html)
- [Database Testing Patterns](https://www.testcontainers.org/test_framework_integration/junit_5/)

---

## Submission Instructions

### Details of Submission:

1. **Screenshots Required**:
   - Terminal output showing all tests passing
   - Docker Desktop showing container running during tests
   - Code coverage report (bonus: `go test -cover ./repository`)
   - TestContainers logs showing container lifecycle

2. **Code Files**:
   - `models/user.go`
   - `repository/user_repository.go`
   - `repository/user_repository_test.go`
   - `migrations/init.sql`
   - `go.mod` and `go.sum`

3. **Documentation**:
   - `README.md` explaining:
     - Commands on how to run the tests
     - Challenges faced and solutions
     - Test coverage achieved

### Submission Checklist:

- [ ] All exercises completed
- [ ] Tests passing (`go test ./repository -v`)
- [ ] Code coverage > 80%
- [ ] Screenshots captured
- [ ] README.md written
- [ ] Code is well-commented
- [ ] All code files included
- [ ] TestContainers setup working locally

---

_This practical is part of the Software Testing & Quality Assurance module._

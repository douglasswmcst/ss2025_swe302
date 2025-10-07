# Practical 5 TestContainers Example

Complete reference implementation for Practical 5 - Integration Testing with TestContainers.

## Overview

This project demonstrates:
- Integration testing with TestContainers
- PostgreSQL database testing
- Full CRUD operations
- Advanced queries (pattern matching, counting, date filtering)
- Transaction testing and isolation
- Multi-container setup with Redis caching

## Prerequisites

- Go 1.21 or higher
- Docker Desktop running
- ~500MB disk space for Docker images

## Quick Start

```bash
# Clone/navigate to project
cd practicals/practical5-example

# Download dependencies
go mod download

# Run all tests
go test ./... -v

# Run tests with coverage
go test -cover ./repository

# Run specific test suite
go test ./repository -run TestGetByID -v
```

## Project Structure

```
practical5-example/
├── models/
│   └── user.go                          # User data model
├── repository/
│   ├── user_repository.go               # Basic CRUD operations
│   ├── user_repository_test.go          # Integration tests (Exercises 1-4)
│   ├── cached_user_repository.go        # Redis caching layer
│   └── cached_user_repository_test.go   # Multi-container tests (Exercise 5)
├── migrations/
│   └── init.sql                         # Database schema
├── go.mod                               # Dependencies
└── README.md                            # This file
```

## Exercises Covered

### Exercise 1-2: Basic CRUD (user_repository_test.go)
- `TestGetByID` - Retrieve user by ID
- `TestGetByEmail` - Retrieve user by email
- `TestCreate` - Create new user
- `TestUpdate` - Update existing user
- `TestDelete` - Delete user
- `TestList` - List all users

### Exercise 3: Advanced Queries (user_repository.go)
- `FindByNamePattern` - Pattern matching with ILIKE
- `CountUsers` - Count total users
- `GetRecentUsers` - Filter by date range

### Exercise 4: Transactions (user_repository.go)
- `BatchCreate` - Atomic batch operations
- `TransferUserData` - Complex transactions
- `TestTransactionRollback` - Verify rollback behavior
- `TestConcurrentWrites` - Concurrent access

### Exercise 5: Multi-Container (cached_user_repository_test.go)
- PostgreSQL + Redis setup
- Cache hit/miss testing
- Cache invalidation
- TTL verification

## Running Tests

### All Tests
```bash
go test ./... -v
```

### With Coverage
```bash
go test -cover ./repository
go test -coverprofile=coverage.out ./repository
go tool cover -html=coverage.out
```

### Race Detection
```bash
go test -race ./repository
```

### Specific Test
```bash
go test ./repository -run TestGetByID -v
```

### Skip Slow Tests
```bash
go test ./repository -short
```

## Understanding the Tests

### TestMain Setup
Each test file has a `TestMain` function that:
1. Starts Docker container(s)
2. Waits for services to be ready
3. Initializes database schema
4. Runs all tests
5. Cleans up containers

### Test Isolation
Tests maintain isolation through:
- Deferred cleanup (`defer repo.Delete(user.ID)`)
- Transaction rollback for some tests
- Shared container with careful data management

### Container Lifecycle
```
Test Start → Container Starts → Database Initializes → Tests Run → Container Stops
```

## Troubleshooting

### "Cannot connect to Docker daemon"
- Ensure Docker Desktop is running
- Check: `docker ps`

### "Container startup timeout"
- Increase timeout in wait strategy
- Check Docker has enough resources

### "Tests are slow"
- First run downloads images (one-time cost)
- Subsequent runs use cached images
- Consider parallel test execution

### "Port conflicts"
- TestContainers uses random ports
- No manual port configuration needed

## Key Learnings

1. **Real Database Testing**: Tests run against actual PostgreSQL, not mocks
2. **Container Lifecycle**: Automatic setup and teardown
3. **Test Isolation**: Each test can have clean state
4. **CI/CD Ready**: Works in any environment with Docker
5. **Production-Like**: Same database as production

## Next Steps

- Apply TestContainers to your own projects
- Try other databases (MySQL, MongoDB)
- Experiment with message queues (Kafka, RabbitMQ)
- Add API layer and test end-to-end
- Explore performance optimization

## Resources

- [TestContainers Go Docs](https://golang.testcontainers.org/)
- [PostgreSQL Module](https://golang.testcontainers.org/modules/postgres/)
- [Redis Module](https://golang.testcontainers.org/modules/redis/)
- Main Tutorial: `../practical5.md`

## License

Educational use for SWE302 - Software Testing & Quality Assurance

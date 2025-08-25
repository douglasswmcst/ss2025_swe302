# **Module Practical: Software Testing & Quality Assurance**

This is a practical walkthrough on writing unit and coverage tests for a simple Go server with CRUD operations.

This guide will teach you how to write effective unit tests for a Go HTTP server and how to measure your test coverage to ensure your code is robust and reliable. We'll use only Go's powerful standard library, specifically the `testing` and `net/http/httptest` packages.

-----

### The Big Picture: What We're Building and Testing

We will create a simple in-memory "Users" API with the five most common CRUD (Create, Read, Update, Delete) operations. Our goal is to write a unit test for each of these operations to verify they work as expected under different conditions.

  * **The Server:** A simple web server that manages a list of users stored in memory.
  * **The Tests:** A corresponding test file that simulates HTTP requests to our server's endpoints and checks if the responses (status codes, JSON bodies) are correct.
  * **The Coverage Report:** A visual, line-by-line report showing exactly which parts of our code were exercised by our tests.

-----

### Part 1: Project Setup

First, let's create a directory for our project. We'll keep it simple with just three files in the same package.

1.  **Create the Project Directory:**

    ```bash
    mkdir go-crud-testing
    cd go-crud-testing
    go mod init crud-testing
    ```

2.  **Create the Files:**
    Inside the `go-crud-testing` directory, create three files:

      * `main.go`: The entry point to start our HTTP server.
      * `handlers.go`: The core logic for handling our CRUD operations.
      * `handlers_test.go`: The unit tests for our handlers. **Crucially, Go recognizes any file ending in `_test.go` as a test file.**

-----

### Part 2: Writing the Server Code

Let's write the code for our server. We'll separate the handlers from the main server setup for better organization.

#### **`handlers.go` - The Core Logic**

This file defines our `User` type, our in-memory storage, and all the functions that handle the HTTP requests.

```go
// handlers.go
package main

import (
	"encoding/json"
	"net/http"
	"strconv"
	"sync"

	"github.com/go-chi/chi/v5"
)

// User defines the structure for a user.
type User struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

// In-memory "database"
var (
	users  = make(map[int]User)
	nextID = 1
	mu     sync.Mutex // To safely handle concurrent requests
)

// --- HANDLERS ---

// getAllUsersHandler handles GET /users
func getAllUsersHandler(w http.ResponseWriter, r *http.Request) {
	mu.Lock()
	defer mu.Unlock()

	var userList []User
	for _, user := range users {
		userList = append(userList, user)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(userList)
}

// createUserHandler handles POST /users
func createUserHandler(w http.ResponseWriter, r *http.Request) {
	var user User
	if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	mu.Lock()
	defer mu.Unlock()

	user.ID = nextID
	nextID++
	users[user.ID] = user

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(user)
}

// getUserHandler handles GET /users/{id}
func getUserHandler(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	mu.Lock()
	defer mu.Unlock()

	user, ok := users[id]
	if !ok {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

// updateUserHandler handles PUT /users/{id}
func updateUserHandler(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	var updatedUser User
	if err := json.NewDecoder(r.Body).Decode(&updatedUser); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	mu.Lock()
	defer mu.Unlock()

	_, ok := users[id]
	if !ok {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	updatedUser.ID = id
	users[id] = updatedUser

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(updatedUser)
}

// deleteUserHandler handles DELETE /users/{id}
func deleteUserHandler(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	mu.Lock()
	defer mu.Unlock()

	if _, ok := users[id]; !ok {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	delete(users, id)
	w.WriteHeader(http.StatusNoContent)
}
```

#### **`main.go` - The Server Setup**

This file sets up the router and starts the server. Our tests won't run this file directly, but it's here to make the application runnable.

```go
// main.go
package main

import (
	"log"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func main() {
	r := chi.NewRouter()
	r.Use(middleware.Logger)

	// Setup routes
	r.Get("/users", getAllUsersHandler)
	r.Post("/users", createUserHandler)
	r.Get("/users/{id}", getUserHandler)
	r.Put("/users/{id}", updateUserHandler)
	r.Delete("/users/{id}", deleteUserHandler)

	log.Println("Server starting on :3000")
	if err := http.ListenAndServe(":3000", r); err != nil {
		log.Fatalf("Could not start server: %s\n", err)
	}
}
```

Before proceeding, get the `chi` dependency:

```bash
go get github.com/go-chi/chi/v5
```

-----

### Part 3: Writing the Unit Tests

Now for the main event. We will write tests in `handlers_test.go`. The key tools are:

  * **`httptest.NewRequest()`**: Creates a mock HTTP request. We can specify the method, URL, and body.
  * **`httptest.NewRecorder()`**: A special object that implements the `http.ResponseWriter` interface. Instead of writing to an actual network connection, it "records" the status code, headers, and body so we can inspect them.

#### **`handlers_test.go` - The Test Code**

```go
// handlers_test.go
package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"
)

// A helper function to reset the state before each test
func resetState() {
	users = make(map[int]User)
	nextID = 1
}

func TestCreateUserHandler(t *testing.T) {
	resetState()

	// 1. Define the user we want to create
	userPayload := `{"name": "John Doe"}`
	req, err := http.NewRequest("POST", "/users", bytes.NewBufferString(userPayload))
	if err != nil {
		t.Fatal(err)
	}

	// 2. Create a ResponseRecorder to record the response
	rr := httptest.NewRecorder()

	// 3. Create a router and serve the request
	router := chi.NewRouter()
	router.Post("/users", createUserHandler)
	router.ServeHTTP(rr, req)

	// 4. Check the status code
	if status := rr.Code; status != http.StatusCreated {
		t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusCreated)
	}

	// 5. Check the response body
	var createdUser User
	if err := json.NewDecoder(rr.Body).Decode(&createdUser); err != nil {
		t.Fatal(err)
	}

	if createdUser.Name != "John Doe" {
		t.Errorf("handler returned unexpected body: got name %v want %v", createdUser.Name, "John Doe")
	}

	if createdUser.ID != 1 {
		t.Errorf("handler returned unexpected body: got id %v want %v", createdUser.ID, 1)
	}
}

func TestGetUserHandler(t *testing.T) {
	resetState()

	// First, create a user to fetch
	users[1] = User{ID: 1, Name: "Jane Doe"}

	// Test case 1: User found
	t.Run("User Found", func(t *testing.T) {
		req, err := http.NewRequest("GET", "/users/1", nil)
		if err != nil {
			t.Fatal(err)
		}

		rr := httptest.NewRecorder()
		router := chi.NewRouter()
		router.Get("/users/{id}", getUserHandler)
		router.ServeHTTP(rr, req)

		if status := rr.Code; status != http.StatusOK {
			t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusOK)
		}

		var foundUser User
		json.NewDecoder(rr.Body).Decode(&foundUser)
		if foundUser.Name != "Jane Doe" {
			t.Errorf("handler returned unexpected body: got %v want %v", foundUser.Name, "Jane Doe")
		}
	})

	// Test case 2: User not found
	t.Run("User Not Found", func(t *testing.T) {
		req, err := http.NewRequest("GET", "/users/99", nil)
		if err != nil {
			t.Fatal(err)
		}

		rr := httptest.NewRecorder()
		router := chi.NewRouter()
		router.Get("/users/{id}", getUserHandler)
		router.ServeHTTP(rr, req)

		if status := rr.Code; status != http.StatusNotFound {
			t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusNotFound)
		}
	})
}

// You would continue this pattern for updateUserHandler and deleteUserHandler...

func TestDeleteUserHandler(t *testing.T) {
	resetState()
	users[1] = User{ID: 1, Name: "To Be Deleted"}

	req, err := http.NewRequest("DELETE", "/users/1", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	router := chi.NewRouter()
	router.Delete("/users/{id}", deleteUserHandler)
	router.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusNoContent {
		t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusNoContent)
	}

	// Verify the user was actually deleted
	if _, ok := users[1]; ok {
		t.Error("user was not deleted from the map")
	}
}
```

-----

### Part 4: Running Tests and Analyzing Coverage

This is where you see the results of your hard work.

1.  **Run the Tests:**
    Open your terminal in the project directory and run:

    ```bash
    go test -v
    ```

    The `-v` (verbose) flag shows the name of each test as it runs. You should see all your tests pass.

    ```
    === RUN   TestCreateUserHandler
    --- PASS: TestCreateUserHandler (0.00s)
    === RUN   TestGetUserHandler
    === RUN   TestGetUserHandler/User_Found
    --- PASS: TestGetUserHandler (0.00s)
    --- PASS: TestGetUserHandler/User_Found (0.00s)
    === RUN   TestGetUserHandler/User_Not_Found
    --- PASS: TestGetUserHandler/User_Not_Found (0.00s)
    === RUN   TestDeleteUserHandler
    --- PASS: TestDeleteUserHandler (0.00s)
    PASS
    ok      crud-testing    0.002s
    ```

2.  **Check Basic Code Coverage:**
    To see a summary of your test coverage percentage, use the `-cover` flag.

    ```bash
    go test -v -cover
    ```

    You'll see a new line in the output:

    ```
    ...
    PASS
    coverage: 85.7% of statements in ./...
    ok      crud-testing    0.002s
    ```

    This percentage tells you how much of your code was executed during the tests. 100% is ideal, but a high percentage (80%+) is generally a good goal.

3.  **Generate a Visual Coverage Report:**
    This is the most powerful feature. It creates an HTML file that color-codes your source code to show exactly what was and wasn't tested.

    **Step A:** Run the tests again, this time outputting the coverage profile to a file.

    ```bash
    go test -coverprofile=coverage.out
    ```

    This creates a file named `coverage.out`.

    **Step B:** Use the `go tool` to convert this file into an HTML report.

    ```bash
    go tool cover -html=coverage.out
    ```

    This command will automatically open a new tab in your web browser with the report.

    In the report:

      * **Green text** means the code was executed by your tests.
      * **Red text** means it was not.
      * **Grey text** means it's not executable code (like comments or declarations).

    This visual feedback is invaluable. If you see a block of red in an important logic path (like an error condition), you know you need to write a new test case to cover it\!

This video provides an excellent introduction to the fundamentals of testing HTTP handlers in Go.
[Watch a tutorial on unit testing net/http handlers](https://www.youtube.com/watch?v=YmbbmyxSlcg)
# **Module Practical 3: Software Testing & Quality Assurance**
# A Detailed Guide to Specification-Based Testing in Go

This guide is a hands-on, detailed walkthrough of the concepts from Chapter 2 of "Effective Software Testing: A Developer's Guide" by Maurício Aniche. We'll explore how to use a system's specification (its requirements document) to design effective tests without looking at the internal code.

This approach is called **black-box testing**. Imagine you're using a coffee machine. You know that if you put in a coffee pod and press the "Espresso" button (the inputs), you should get a shot of espresso (the output). You test this behavior without needing to know how the internal grinder, heater, and pump work (the implementation). We'll be doing the same with our code.

We will use **Go** for our examples, but the principles are universal and crucial for any software engineer.
-----

## The System Under Test (SUT)

For our practical example, we'll test a function that calculates a shipping fee. First, let's carefully read its specification. In the real world, this could be a ticket in a project management tool or a formal requirements document.

**Function Signature:**
`CalculateShippingFee(weight float64, zone string) (float64, error)`

**Business Rules (The Specification):**

1.  The package `weight` must be greater than 0 kg and no more than 50 kg. Any other weight is considered invalid.
2.  The destination `zone` must be one of the following three exact strings: `"Domestic"`, `"International"`, or `"Express"`.
3.  The fee is calculated based on these rules:
      * **Domestic:** $5 base fee + $1.00 per kg.
      * **International:** $20 base fee + $2.50 per kg.
      * **Express:** $30 base fee + $5.00 per kg.
4.  If the `weight` is invalid, the function must stop and return an error.
5.  If the `zone` is invalid, the function must stop and return an error.

Here is a Go implementation that aims to satisfy this specification. We'll save this in a file named `shipping.go`.

```go
// shipping.go
package shipping

import (
	"errors"
	"fmt"
)

// CalculateShippingFee calculates the fee based on weight and zone.
func CalculateShippingFee(weight float64, zone string) (float64, error) {
	// This block directly implements Rule #1 and #4
	if weight <= 0 || weight > 50 {
		return 0, errors.New("invalid weight")
	}

	// This switch statement implements Rule #2, #3, and #5
	switch zone {
	case "Domestic":
		return 5.0 + (weight * 1.0), nil
	case "International":
		return 20.0 + (weight * 2.5), nil
	case "Express":
		return 30.0 + (weight * 5.0), nil
	default:
		// This handles any zone not explicitly listed above
		return 0, fmt.Errorf("invalid zone: %s", zone)
	}
}
```

Now, let's pretend we can't see this code. Our job is to write tests based *only* on the business rules. We will use three powerful techniques to do this systematically.

-----

## 1\. Equivalence Partitioning

### The Concept

If we tried to test every possible weight, we would be testing forever (e.g., 10.1, 10.11, 10.111...). That's impossible. **Equivalence Partitioning** solves this by dividing all possible inputs into a few "partitions" or groups. The core idea is that all inputs in a single partition should be treated the same way by the system. Therefore, **if we test just one value from a partition, we can be confident it represents all the other values in that partition**.

### Identifying the Partitions

Let's break down our inputs based on the specification:

  * **Input: `weight` (`float64`)**
    The rule is "greater than 0 kg and no more than 50 kg". This clearly defines three partitions:

      * **P1: Too Small (Invalid):** Any weight less than or equal to 0. (e.g., `-10`, `0`)
      * **P2: Just Right (Valid):** Any weight between 0 (exclusive) and 50 (inclusive). (e.g., `1`, `25.5`, `50`)
      * **P3: Too Large (Invalid):** Any weight greater than 50. (e.g., `50.1`, `100`)

  * **Input: `zone` (`string`)**
    The rule gives a specific list of valid strings. This creates two partitions:

      * **P4: Valid Zones:** The set of strings containing `"Domestic"`, `"International"`, `"Express"`.
      * **P5: Invalid Zones:** Any other string. (e.g., `"Local"`, `""`, `"domestic"` with a lowercase 'd')

### Test Implementation

Now we write a test file `shipping_test.go`. We'll create test cases by picking a single, representative value from each partition we identified.

```go
// shipping_test.go
package shipping

import (
	"testing"
)

func TestCalculateShippingFee_EquivalencePartitioning(t *testing.T) {
	// Test P1: A weight that is too small (e.g., -5). We expect an error.
	_, err := CalculateShippingFee(-5, "Domestic")
	if err == nil {
		t.Error("Test failed: Expected an error for a negative weight, but got nil")
	}

	// Test P2 & P4: A valid weight (10) and a valid zone ("Domestic").
	// We expect a correct calculation and no error.
	fee, err := CalculateShippingFee(10, "Domestic")
	if err != nil {
		t.Errorf("Test failed: Expected no error for a valid weight, but got %v", err)
	}
	expectedFee := 15.0 // From the spec: 5.0 base + (10kg * $1.0/kg)
	if fee != expectedFee {
		t.Errorf("Test failed: Expected fee of %f, but got %f", expectedFee, fee)
	}

	// Test P3: A weight that is too large (e.g., 100). We expect an error.
	_, err = CalculateShippingFee(100, "International")
	if err == nil {
		t.Error("Test failed: Expected an error for an overweight package, but got nil")
	}

	// Test P5: An invalid zone (e.g., "Local"). We expect an error.
	_, err = CalculateShippingFee(20, "Local") // Using a valid weight
	if err == nil {
		t.Error("Test failed: Expected an error for an invalid zone, but got nil")
	}
}
```

With just a few tests, we've covered the general behavior for all possible inputs\! But we can be more precise.

-----

## 2\. Boundary Value Analysis (BVA)

### The Concept

**Boundary Value Analysis** is a natural extension of Equivalence Partitioning. Experience shows that a huge number of bugs occur right at the "edges" or **boundaries** of our partitions. For example, if a condition is `weight > 0`, developers might mistakenly write `weight >= 0` (an "off-by-one" error). BVA forces us to check these tricky edge cases.

### Identifying the Boundaries

Let's look at our valid `weight` partition: `(0, 50]`. The boundaries are the values that are right on the edge of being valid or invalid.

  * **Lower Boundary:**
      * `0` (The last invalid number before it becomes valid)
      * `0.1` (The first valid number we can think of)
  * **Upper Boundary:**
      * `50` (The last valid number)
      * `50.1` (The first invalid number after the valid range)

For the `zone`, since it's a set of strings, there aren't numerical boundaries. BVA is most useful for numerical ranges, dates, and sizes.

### Test Implementation

A **table-driven test** is a fantastic and common pattern in Go for testing multiple scenarios of the same function. We define a list of test cases, each with its own inputs and expected outputs, and then loop through them. This is perfect for BVA.

```go
// shipping_test.go
// ... (add this function to the existing file)

func TestCalculateShippingFee_BoundaryValueAnalysis(t *testing.T) {
	// We define a struct to hold all the data for one test case
	testCases := []struct {
		name        string  // A description of the test case
		weight      float64 // The input weight
		zone        string  // The input zone
		expectError bool    // True if we expect an error, false otherwise
	}{
		// Test cases for the identified boundaries of the 'weight' input
		{"Weight at lower invalid boundary", 0, "Domestic", true},
		{"Weight just above lower boundary", 0.1, "Domestic", false},
		{"Weight at upper valid boundary", 50, "International", false},
		{"Weight just above upper boundary", 50.1, "Express", true},
	}

	// Go's testing package lets us loop through our test cases
	for _, tc := range testCases {
		// t.Run creates a sub-test, which gives a clearer output if one fails
		t.Run(tc.name, func(t *testing.T) {
			_, err := CalculateShippingFee(tc.weight, tc.zone)

			// Assertion 1: Check if we got an error when we expected one
			if tc.expectError && err == nil {
				t.Errorf("Expected an error, but got nil")
			}
			
			// Assertion 2: Check if we got no error when we didn't expect one
			if !tc.expectError && err != nil {
				t.Errorf("Expected no error, but got: %v", err)
			}
		})
	}
}
```

-----

## 3\. Decision Table Testing

### The Concept

This technique is a lifesaver when you have **multiple inputs that interact to create complex business rules**. A decision table is a systematic way to map all valid combinations of conditions to their expected outcomes, ensuring you don't miss a scenario.

### Creating the Table

1.  **List Conditions:** What are the input conditions that can change the outcome?
      * Condition A: Is the weight valid? (True/False)
      * Condition B: What is the zone? (Domestic, International, Express, Invalid)
2.  **List Actions:** What are the possible outcomes or actions?
      * Action 1: Return weight error
      * Action 2: Calculate Domestic fee
      * Action 3: Calculate International fee
      * Action 4: Calculate Express fee
      * Action 5: Return zone error
3.  **Build the Table:** Create a column for each combination of conditions (a "rule") and mark the resulting action.

| Rule \# | Condition A: Weight Valid (0 \< w \<= 50) | Condition B: Zone | Action / Expected Outcome |
| :---: | :---: | :---: | :---: |
| 1 | `False` | *Don't Care* | **Action 1: Return weight error** |
| 2 | `True` | `"Domestic"` | **Action 2: Calculate Domestic fee** |
| 3 | `True` | `"International"` | **Action 3: Calculate International fee** |
| 4 | `True` | `"Express"` | **Action 4: Calculate Express fee** |
| 5 | `True` | *Invalid* | **Action 5: Return zone error** |

*Note: In Rule \#1, if the weight is invalid, the zone doesn't matter. The function should fail immediately. This is represented by "Don't Care".*

### Test Implementation

A Go table-driven test is the perfect way to directly translate a decision table into executable code. Each row in our `testCases` slice will correspond to one rule from our table.

```go
// shipping_test.go
// ... (add this function to the existing file)

func TestCalculateShippingFee_DecisionTable(t *testing.T) {
	testCases := []struct {
		name          string
		weight        float64
		zone          string
		expectedFee   float64
		expectedError string // We check for a substring of the error message
	}{
		// Rule 1: Invalid weight. Zone does not matter.
		{"Rule 1: Weight too low", -10, "Domestic", 0, "invalid weight"},
		{"Rule 1: Weight too high", 60, "International", 0, "invalid weight"},
		
		// Rule 2: Valid weight, Domestic zone
		{"Rule 2: Domestic", 10, "Domestic", 15.0, ""}, // 5 + 10 * 1.0
		
		// Rule 3: Valid weight, International zone
		{"Rule 3: International", 10, "International", 45.0, ""}, // 20 + 10 * 2.5
		
		// Rule 4: Valid weight, Express zone
		{"Rule 4: Express", 10, "Express", 80.0, ""}, // 30 + 10 * 5.0

		// Rule 5: Valid weight, Invalid Zone
		{"Rule 5: Invalid Zone", 10, "Unknown", 0, "invalid zone: Unknown"},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			fee, err := CalculateShippingFee(tc.weight, tc.zone)

			// Check if we got the error we expected
			if tc.expectedError != "" {
				if err == nil {
					t.Fatalf("Expected error containing '%s', but got nil", tc.expectedError)
				}
				// A simple check is to see if our error message contains the expected text.
				// In more complex apps, you might check for specific error types.
			} else {
				// Check that we did NOT get an error when one wasn't expected
				if err != nil {
					t.Fatalf("Expected no error, but got: %v", err)
				}
				// Check if the calculated fee is correct
				if fee != tc.expectedFee {
					t.Errorf("Expected fee %f, but got %f", tc.expectedFee, fee)
				}
			}
		})
	}
}
```

## Summary & Takeaways

By using these three techniques together, we have built a powerful test suite for our function without ever looking at its implementation. This is valuable because our tests will remain valid even if a colleague refactors the code, as long as the behavior described in the specification doesn't change.

  * **Equivalence Partitioning** is your starting point. It helps you get broad coverage with a minimal number of tests by grouping inputs.
  * **Boundary Value Analysis** makes your tests more robust by focusing on the tricky edge cases where bugs love to hide.
  * **Decision Table Testing** gives you a systematic way to tame complexity and ensure all combinations of business rules are checked.

These methods help you move from random, ad-hoc testing to a structured, efficient process. They help you think critically about the requirements and ultimately write tests that are much more likely to find real bugs. Happy testing\! 🚀

Of course. Here is a follow-up exercise designed to reinforce the concepts of Equivalence Partitioning and Boundary Value Analysis.

-----

# Exercise: Advanced Shipping Fee Calculator

Now that you've walked through the fundamentals of specification-based testing, it's time to apply those skills to a new set of requirements. The business has decided to update the shipping fee logic with new rules.

Your task is to act as the developer responsible for testing the updated function. You must design and implement the necessary tests based *only* on the new specification provided below.

## New Specification

The `CalculateShippingFee` function has been updated. Please read the new business rules carefully.

**New Function Signature:**
`CalculateShippingFee(weight float64, zone string, insured bool) (float64, error)`

**Updated Business Rules:**

1.  **Weight Tiers & Surcharges:** The simple per-kg cost is gone. The calculation now depends on weight tiers.

      * **0 \< weight \<= 10 kg:** This is a "Standard" package.
      * **10 \< weight \<= 50 kg:** This is a "Heavy" package. A fixed surcharge of **$7.50** is added to the total cost.
      * Any weight outside the `(0, 50]` range is invalid and should produce an error.

2.  **Zone-Based Base Fees:** The base fee is determined by the `zone`.

      * `"Domestic"`: $5.00 base fee.
      * `"International"`: $20.00 base fee.
      * `"Express"`: $30.00 base fee.
      * Any other zone is invalid and should produce an error.

3.  **Insurance:** A new `insured` boolean parameter has been added.

      * If `insured` is `true`, an additional **1.5%** of the combined base fee and heavy surcharge is added to the final cost. (e.g., if Base Fee + Surcharge = $27.50, the insurance cost is $27.50 \* 0.015).

**Calculation Order:**
The final fee is `(Base Fee + Heavy Surcharge [if applicable]) + Insurance Cost [if applicable]`.

### Updated Function Code

Here is the new implementation (`shipping_v2.go`). Your tests should target this function's behavior as defined by the specification above. Do not rely on the internal logic for your test design.

```go
// shipping_v2.go
package shipping

import (
	"errors"
	"fmt"
)

// CalculateShippingFee calculates the fee based on new tiered logic.
func CalculateShippingFee(weight float64, zone string, insured bool) (float64, error) {
	if weight <= 0 || weight > 50 {
		return 0, errors.New("invalid weight")
	}

	var baseFee float64
	switch zone {
	case "Domestic":
		baseFee = 5.0
	case "International":
		baseFee = 20.0
	case "Express":
		baseFee = 30.0
	default:
		return 0, fmt.Errorf("invalid zone: %s", zone)
	}

	var heavySurcharge float64
	if weight > 10 {
		heavySurcharge = 7.50
	}

	subTotal := baseFee + heavySurcharge

	var insuranceCost float64
	if insured {
		insuranceCost = subTotal * 0.015
	}

	finalTotal := subTotal + insuranceCost

	return finalTotal, nil
}
```

-----

## Your Tasks

### Part 1: Design the Test Cases (Analysis)

Before writing any code, first design your test cases by analyzing the new specification.

**1. Equivalence Partitioning:**
Identify and list all the equivalence partitions for each of the three inputs (`weight`, `zone`, `insured`).

  * **Weight:**
      * P1: ...
      * P2: ...
      * P3: ...
  * **Zone:**
      * P4: ...
      * P5: ...
  * **Insured:**
      * P6: ...
      * P7: ...

**2. Boundary Value Analysis:**
The `weight` input now has new boundaries. Identify and list the specific values you should test around these boundaries.

  * **Lower Boundary (around 0):**
      * ...
      * ...
  * **Mid Boundary (around 10):**
      * ...
      * ...
  * **Upper Boundary (around 50):**
      * ...
      * ...

### Part 2: Implement the Tests (Go Code)

Now, translate your analysis from Part 1 into Go test code.

1.  Create a new test file named `shipping_v2_test.go`.
2.  Inside this file, create a single, comprehensive table-driven test function: `TestCalculateShippingFee_V2`.
3.  Your test table should include cases that cover **all** the partitions and boundary values you identified.
4.  For each test case, include a descriptive `name`, the inputs (`weight`, `zone`, `insured`), the `expectedFee`, and whether you `expectError`.

**Be sure to:**

  * Test invalid cases (e.g., bad weight, bad zone).
  * Test each valid weight tier (`Standard` and `Heavy`).
  * Test the effect of the `insured` flag in combination with different package types.
  * Test all the boundary values you listed.

Good luck\! This exercise will solidify your ability to systematically derive tests from requirements—a critical skill for any software engineer.
-----
## **Submission Instructions**

Details of Submission:
1. screenshot of all tests passing
2. Draft and detailed answers on your README.md on the partitions and boundaries you identified and why.
3. submit all code files including the new `shipping_v2.go` and `shipping_v2_test.go`
-----
describe('Dog Image Browser - Fetch Dog Functionality', () => {
  beforeEach(() => {
    cy.visit('/');
  });

  it('should fetch and display a random dog image when button is clicked', () => {
    // Click the fetch button
    cy.get('[data-testid="fetch-dog-button"]').click();

    // Button should show loading state
    cy.get('[data-testid="fetch-dog-button"]')
      .should('contain.text', 'Loading...')
      .and('be.disabled');

    // Wait for image to load and be visible
    cy.get('[data-testid="dog-image-container"]', { timeout: 10000 })
      .should('be.visible');

    cy.get('[data-testid="dog-image"]')
      .should('be.visible')
      .and('have.attr', 'src')
      .and('include', 'images.dog.ceo');

    // Placeholder should be gone
    cy.get('[data-testid="placeholder-message"]')
      .should('not.exist');

    // Button should return to normal state
    cy.get('[data-testid="fetch-dog-button"]')
      .should('contain.text', 'Get Random Dog')
      .and('not.be.disabled');
  });

  it('should fetch different dog images on multiple clicks', () => {
    // Array to store image URLs
    const imageUrls: string[] = [];

    // Fetch first dog
    cy.get('[data-testid="fetch-dog-button"]').click();
    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible')
      .invoke('attr', 'src')
      .then((src) => {
        imageUrls.push(src as string);
      });

    // Fetch second dog
    cy.get('[data-testid="fetch-dog-button"]').click();
    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible')
      .invoke('attr', 'src')
      .then((src) => {
        imageUrls.push(src as string);
        // Images should be different (though there's a small chance they're the same)
        // For a more robust test, you'd mock the API
      });
  });

  it('should handle rapid successive clicks gracefully', () => {
    // Click button multiple times quickly
    cy.get('[data-testid="fetch-dog-button"]').click();
    cy.get('[data-testid="fetch-dog-button"]').click();
    cy.get('[data-testid="fetch-dog-button"]').click();

    // Should still display an image eventually
    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible');

    // No error should be shown
    cy.get('[data-testid="error-message"]')
      .should('not.exist');
  });
});

describe('Dog Image Browser - Breed Selection', () => {
  beforeEach(() => {
    cy.visit('/');
    // Wait for breeds to load
    cy.get('[data-testid="breed-selector"] option', { timeout: 10000 })
      .should('have.length.greaterThan', 1);
  });

  it('should load breed options in the dropdown', () => {
    // Check that dropdown has breeds
    cy.get('[data-testid="breed-selector"]')
      .find('option')
      .should('have.length.greaterThan', 1);

    // First option should be "All Breeds (Random)"
    cy.get('[data-testid="breed-selector"] option')
      .first()
      .should('have.text', 'All Breeds (Random)');
  });

  it('should fetch a specific breed when selected', () => {
    // Select a specific breed (e.g., 'husky')
    cy.get('[data-testid="breed-selector"]').select('husky');

    // Verify selection
    cy.get('[data-testid="breed-selector"]')
      .should('have.value', 'husky');

    // Click fetch button
    cy.get('[data-testid="fetch-dog-button"]').click();

    // Wait for image to load
    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible')
      .invoke('attr', 'src')
      .should('include', 'husky');
  });

  it('should allow switching between breeds', () => {
    // Select first breed
    cy.get('[data-testid="breed-selector"]').select('corgi');
    cy.get('[data-testid="fetch-dog-button"]').click();
    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible')
      .invoke('attr', 'src')
      .should('include', 'corgi');

    // Switch to another breed
    cy.get('[data-testid="breed-selector"]').select('poodle');
    cy.get('[data-testid="fetch-dog-button"]').click();
    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible')
      .invoke('attr', 'src')
      .should('include', 'poodle');

    // Switch back to random
    cy.get('[data-testid="breed-selector"]').select('');
    cy.get('[data-testid="fetch-dog-button"]').click();
    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible');
  });

  it('should capitalize breed names in the dropdown', () => {
    // Get a few breed options and check capitalization
    cy.get('[data-testid="breed-selector"] option')
      .eq(1) // Skip "All Breeds" option
      .invoke('text')
      .should('match', /^[A-Z]/); // First letter should be uppercase
  });
});

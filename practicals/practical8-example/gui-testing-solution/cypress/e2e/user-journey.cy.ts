describe('Complete User Journey', () => {
  it('should complete a full user workflow', () => {
    // 1. User visits homepage
    cy.visit('/');

    // 2. User sees welcome message
    cy.get('[data-testid="page-title"]')
      .should('be.visible')
      .and('contain.text', 'Dog Image Browser');

    cy.get('[data-testid="placeholder-message"]')
      .should('be.visible')
      .and('contain.text', 'Click "Get Random Dog" to see a cute dog!');

    // 3. User browses available breeds
    cy.get('[data-testid="breed-selector"] option', { timeout: 10000 })
      .should('have.length.greaterThan', 1);

    // Verify breeds are capitalized
    cy.get('[data-testid="breed-selector"] option')
      .eq(1)
      .invoke('text')
      .should('match', /^[A-Z]/);

    // 4. User selects a specific breed (corgi)
    cy.get('[data-testid="breed-selector"]').select('corgi');
    cy.get('[data-testid="breed-selector"]')
      .should('have.value', 'corgi');

    // 5. User fetches dog image
    cy.get('[data-testid="fetch-dog-button"]')
      .should('contain.text', 'Get Random Dog')
      .click();

    // Loading state should show
    cy.get('[data-testid="fetch-dog-button"]')
      .should('contain.text', 'Loading...')
      .and('be.disabled');

    // 6. User views the image
    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible')
      .and('have.attr', 'src')
      .and('include', 'corgi');

    cy.get('[data-testid="dog-image-container"]')
      .should('be.visible');

    // Placeholder message should be gone
    cy.get('[data-testid="placeholder-message"]')
      .should('not.exist');

    // Button should return to normal
    cy.get('[data-testid="fetch-dog-button"]')
      .should('contain.text', 'Get Random Dog')
      .and('not.be.disabled');

    // 7. User selects different breed (poodle)
    cy.get('[data-testid="breed-selector"]').select('poodle');

    // 8. User fetches another image
    cy.get('[data-testid="fetch-dog-button"]').click();

    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible')
      .and('have.attr', 'src')
      .and('include', 'poodle');

    // 9. User selects "All Breeds" (random)
    cy.get('[data-testid="breed-selector"]').select('');
    cy.get('[data-testid="breed-selector"]')
      .should('have.value', '');

    // 10. User fetches random dog
    cy.get('[data-testid="fetch-dog-button"]').click();

    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible')
      .and('have.attr', 'src')
      .and('include', 'images.dog.ceo');

    // Final verification - all UI elements are in correct state
    cy.get('[data-testid="page-title"]').should('be.visible');
    cy.get('[data-testid="breed-selector"]').should('be.visible').and('not.be.disabled');
    cy.get('[data-testid="fetch-dog-button"]').should('be.visible').and('not.be.disabled');
    cy.get('[data-testid="dog-image-container"]').should('be.visible');
    cy.get('[data-testid="error-message"]').should('not.exist');
  });
});

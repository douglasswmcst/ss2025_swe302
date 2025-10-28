describe('Dog Image Browser - Using Custom Commands', () => {
  beforeEach(() => {
    cy.visit('/');
  });

  it('should fetch dog using custom command', () => {
    cy.fetchDog();
    cy.waitForDogImage();
  });

  it('should select breed and fetch using custom command', () => {
    // Wait for breeds to load
    cy.get('[data-testid="breed-selector"] option', { timeout: 10000 })
      .should('have.length.greaterThan', 1);

    cy.selectBreedAndFetch('husky');
    cy.waitForDogImage()
      .invoke('attr', 'src')
      .should('include', 'husky');
  });

  it('should check error using custom command', () => {
    // Mock API failure
    cy.intercept('GET', '/api/dogs', {
      statusCode: 500,
      body: { error: 'Server Error' },
    }).as('getDogError');

    cy.fetchDog();
    cy.wait('@getDogError');
    cy.checkError('Failed to load dog image');
  });
});

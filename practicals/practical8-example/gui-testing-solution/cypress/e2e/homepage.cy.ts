describe('Dog Image Browser - Homepage', () => {
  beforeEach(() => {
    // Visit homepage before each test
    cy.visit('/');
  });

  it('should display the page title and subtitle', () => {
    // Check that title exists and has correct text
    cy.get('[data-testid="page-title"]')
      .should('be.visible')
      .and('contain.text', 'Dog Image Browser');

    // Check that subtitle exists
    cy.get('[data-testid="page-subtitle"]')
      .should('be.visible')
      .and('contain.text', 'Powered by Dog CEO API');
  });

  it('should display the breed selector and fetch button', () => {
    // Check breed selector exists
    cy.get('[data-testid="breed-selector"]')
      .should('be.visible')
      .and('not.be.disabled');

    // Check button exists
    cy.get('[data-testid="fetch-dog-button"]')
      .should('be.visible')
      .and('contain.text', 'Get Random Dog')
      .and('not.be.disabled');
  });

  it('should display placeholder message initially', () => {
    cy.get('[data-testid="placeholder-message"]')
      .should('be.visible')
      .and('contain.text', 'Click "Get Random Dog" to see a cute dog!');
  });

  it('should not display dog image initially', () => {
    cy.get('[data-testid="dog-image-container"]')
      .should('not.exist');
  });

  it('should not display error message initially', () => {
    cy.get('[data-testid="error-message"]')
      .should('not.exist');
  });
});

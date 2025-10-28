export class DogBrowserPage {
  // Element selectors
  elements = {
    pageTitle: () => cy.get('[data-testid="page-title"]'),
    pageSubtitle: () => cy.get('[data-testid="page-subtitle"]'),
    breedSelector: () => cy.get('[data-testid="breed-selector"]'),
    fetchButton: () => cy.get('[data-testid="fetch-dog-button"]'),
    dogImage: () => cy.get('[data-testid="dog-image"]'),
    dogImageContainer: () => cy.get('[data-testid="dog-image-container"]'),
    errorMessage: () => cy.get('[data-testid="error-message"]'),
    placeholderMessage: () => cy.get('[data-testid="placeholder-message"]'),
  };

  // Actions
  visit() {
    cy.visit('/');
  }

  selectBreed(breed: string) {
    this.elements.breedSelector().select(breed);
  }

  clickFetchButton() {
    this.elements.fetchButton().click();
  }

  waitForDogImage() {
    this.elements.dogImage().should('be.visible', { timeout: 10000 });
  }

  // Assertions
  verifyPageLoaded() {
    this.elements.pageTitle().should('be.visible');
    this.elements.breedSelector().should('be.visible');
    this.elements.fetchButton().should('be.visible');
  }

  verifyDogImageDisplayed() {
    this.elements.dogImageContainer().should('be.visible');
    this.elements.dogImage().should('be.visible');
  }

  verifyErrorDisplayed(message: string) {
    this.elements.errorMessage()
      .should('be.visible')
      .and('contain.text', message);
  }

  verifyLoadingState() {
    this.elements.fetchButton()
      .should('contain.text', 'Loading...')
      .and('be.disabled');
  }

  getDogImageSrc() {
    return this.elements.dogImage().invoke('attr', 'src');
  }
}

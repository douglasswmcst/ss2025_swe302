/// <reference types="cypress" />

// Custom command type definitions
declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Cypress {
    interface Chainable {
      /**
       * Custom command to fetch a dog image
       * @example cy.fetchDog()
       */
      fetchDog(): Chainable<void>;

      /**
       * Custom command to select a breed and fetch dog
       * @param breed - The breed name to select
       * @example cy.selectBreedAndFetch('husky')
       */
      selectBreedAndFetch(breed: string): Chainable<void>;

      /**
       * Custom command to wait for dog image to load
       * @example cy.waitForDogImage()
       */
      waitForDogImage(): Chainable<JQuery<HTMLElement>>;

      /**
       * Custom command to check if error is displayed
       * @example cy.checkError('Failed to load')
       */
      checkError(message: string): Chainable<void>;
    }
  }
}

// Fetch dog image command
Cypress.Commands.add('fetchDog', () => {
  cy.get('[data-testid="fetch-dog-button"]').click();
});

// Select breed and fetch command
Cypress.Commands.add('selectBreedAndFetch', (breed: string) => {
  cy.get('[data-testid="breed-selector"]').select(breed);
  cy.get('[data-testid="fetch-dog-button"]').click();
});

// Wait for dog image to load
Cypress.Commands.add('waitForDogImage', () => {
  return cy.get('[data-testid="dog-image"]', { timeout: 10000 })
    .should('be.visible');
});

// Check error message
Cypress.Commands.add('checkError', (message: string) => {
  cy.get('[data-testid="error-message"]')
    .should('be.visible')
    .and('contain.text', message);
});

export {};

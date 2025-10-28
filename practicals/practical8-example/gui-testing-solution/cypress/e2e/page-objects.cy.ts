import { DogBrowserPage } from '../support/page-objects/DogBrowserPage';

describe('Dog Image Browser - Using Page Objects', () => {
  const page = new DogBrowserPage();

  beforeEach(() => {
    page.visit();
  });

  it('should verify page loads correctly', () => {
    page.verifyPageLoaded();
  });

  it('should fetch and display dog image', () => {
    page.clickFetchButton();
    page.waitForDogImage();
    page.verifyDogImageDisplayed();
  });

  it('should select breed and fetch', () => {
    // Wait for breeds to load
    page.elements.breedSelector().find('option').should('have.length.greaterThan', 1);

    page.selectBreed('husky');
    page.clickFetchButton();
    page.waitForDogImage();

    page.getDogImageSrc().should('include', 'husky');
  });

  it('should display error message on API failure', () => {
    cy.intercept('GET', '/api/dogs', {
      statusCode: 500,
      body: { error: 'Server Error' },
    }).as('getDogError');

    page.clickFetchButton();
    cy.wait('@getDogError');
    page.verifyErrorDisplayed('Failed to load dog image');
  });
});

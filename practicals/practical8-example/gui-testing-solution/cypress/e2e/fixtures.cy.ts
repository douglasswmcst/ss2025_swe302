describe('Dog Image Browser - Using Fixtures', () => {
  beforeEach(() => {
    cy.visit('/');
  });

  it('should use fixture data for mocking', () => {
    // Load fixture and use it
    cy.fixture('dog-responses.json').then((data) => {
      cy.intercept('GET', '/api/dogs', {
        statusCode: 200,
        body: data.randomDog,
      }).as('getDog');

      cy.fetchDog();
      cy.wait('@getDog');

      cy.get('[data-testid="dog-image"]')
        .should('have.attr', 'src')
        .and('include', 'n02110185_1469.jpg');
    });
  });

  it('should mock breeds list with fixture', () => {
    cy.fixture('dog-responses.json').then((data) => {
      cy.intercept('GET', '/api/dogs/breeds', {
        statusCode: 200,
        body: data.breedList,
      }).as('getBreeds');

      cy.reload();
      cy.wait('@getBreeds');

      // Check that mocked breeds appear
      cy.get('[data-testid="breed-selector"]')
        .find('option')
        .should('have.length', 6); // 5 breeds + "All Breeds" option
    });
  });
});

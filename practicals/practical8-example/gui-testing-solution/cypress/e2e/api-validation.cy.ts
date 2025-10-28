describe('Dog Image Browser - API Response Validation', () => {
  it('should validate breeds API response structure', () => {
    cy.request('/api/dogs/breeds').then((response) => {
      // Check status code
      expect(response.status).to.eq(200);

      // Check response body structure
      expect(response.body).to.have.property('message');
      expect(response.body).to.have.property('status');
      expect(response.body.status).to.eq('success');

      // Check that message is an object with breed names
      expect(response.body.message).to.be.an('object');
      const breeds = Object.keys(response.body.message);
      expect(breeds.length).to.be.greaterThan(0);
    });
  });

  it('should validate random dog API response structure', () => {
    cy.request('/api/dogs').then((response) => {
      expect(response.status).to.eq(200);
      expect(response.body).to.have.property('message');
      expect(response.body).to.have.property('status');
      expect(response.body.status).to.eq('success');

      // Message should be a URL string
      expect(response.body.message).to.be.a('string');
      expect(response.body.message).to.include('https://images.dog.ceo');
    });
  });

  it('should validate specific breed API response', () => {
    cy.request('/api/dogs?breed=husky').then((response) => {
      expect(response.status).to.eq(200);
      expect(response.body.message).to.be.an('array');
      expect(response.body.message[0]).to.include('husky');
    });
  });
});

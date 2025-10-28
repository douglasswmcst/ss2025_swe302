'use client';

import { useState, useEffect } from 'react';
import Image from 'next/image';

interface DogApiResponse {
  message: string | string[];
  status: string;
}

interface BreedsResponse {
  message: Record<string, string[]>;
  status: string;
}

export default function Home() {
  const [dogImage, setDogImage] = useState<string>('');
  const [breeds, setBreeds] = useState<string[]>([]);
  const [selectedBreed, setSelectedBreed] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>('');

  // Fetch all breeds on mount
  useEffect(() => {
    fetchBreeds();
  }, []);

  const fetchBreeds = async () => {
    try {
      const response = await fetch('/api/dogs/breeds');
      const data: BreedsResponse = await response.json();
      if (data.status === 'success') {
        const breedList = Object.keys(data.message);
        setBreeds(breedList);
      }
    } catch {
      setError('Failed to load breeds');
    }
  };

  const fetchRandomDog = async () => {
    setLoading(true);
    setError('');
    try {
      const url = selectedBreed
        ? `/api/dogs?breed=${selectedBreed}`
        : '/api/dogs';
      const response = await fetch(url);
      const data: DogApiResponse = await response.json();

      if (data.status === 'success') {
        const imageUrl = Array.isArray(data.message)
          ? data.message[0]
          : data.message;
        setDogImage(imageUrl);
      }
    } catch {
      setError('Failed to load dog image');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800 py-12 px-4">
      <main className="max-w-4xl mx-auto">
        <div className="text-center mb-8">
          <h1
            data-testid="page-title"
            className="text-4xl font-bold text-gray-900 dark:text-white mb-2"
          >
            Dog Image Browser
          </h1>
          <p
            data-testid="page-subtitle"
            className="text-gray-600 dark:text-gray-300"
          >
            Powered by Dog CEO API
          </p>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-xl p-6 mb-6">
          <div className="flex flex-col sm:flex-row gap-4 mb-6">
            <select
              data-testid="breed-selector"
              value={selectedBreed}
              onChange={(e) => setSelectedBreed(e.target.value)}
              className="flex-1 px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
            >
              <option value="">All Breeds (Random)</option>
              {breeds.map((breed) => (
                <option key={breed} value={breed}>
                  {breed.charAt(0).toUpperCase() + breed.slice(1)}
                </option>
              ))}
            </select>
            <button
              data-testid="fetch-dog-button"
              onClick={fetchRandomDog}
              disabled={loading}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors font-medium"
            >
              {loading ? 'Loading...' : 'Get Random Dog'}
            </button>
          </div>

          {error && (
            <div
              data-testid="error-message"
              className="mb-4 p-4 bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-200 rounded-lg"
            >
              {error}
            </div>
          )}

          {dogImage && (
            <div
              data-testid="dog-image-container"
              className="relative w-full aspect-square max-w-2xl mx-auto rounded-lg overflow-hidden bg-gray-100 dark:bg-gray-700"
            >
              <Image
                data-testid="dog-image"
                src={dogImage}
                alt="Random dog"
                fill
                className="object-cover"
                sizes="(max-width: 768px) 100vw, 672px"
                priority
              />
            </div>
          )}

          {!dogImage && !loading && (
            <div
              data-testid="placeholder-message"
              className="text-center py-20 text-gray-500 dark:text-gray-400"
            >
              Click &quot;Get Random Dog&quot; to see a cute dog!
            </div>
          )}
        </div>

        <div className="text-center text-sm text-gray-600 dark:text-gray-400">
          <p>Practice GUI testing with Cypress</p>
        </div>
      </main>
    </div>
  );
}

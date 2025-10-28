import { NextResponse } from 'next/server';

// GET /api/dogs - List all breeds
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const breed = searchParams.get('breed');
    const count = searchParams.get('count') || '1';

    let apiUrl: string;

    if (breed) {
      apiUrl = `https://dog.ceo/api/breed/${breed}/images/random/${count}`;
    } else {
      apiUrl = `https://dog.ceo/api/breeds/image/random`;
    }

    const response = await fetch(apiUrl);
    const data = await response.json();

    return NextResponse.json(data);
  } catch {
    return NextResponse.json(
      { error: 'Failed to fetch dog images' },
      { status: 500 }
    );
  }
}

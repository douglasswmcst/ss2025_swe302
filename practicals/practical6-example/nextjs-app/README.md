# Practical 6 Next.js Application

Simple Next.js application configured for static export and S3 deployment.

## Local Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Open http://localhost:3000
```

## Build for Production

```bash
# Build static site
npm run build

# Output will be in ./out directory
ls -la out/
```

## Configuration

- `next.config.js`: Configured for static export
- `buildspec.yml`: CodeBuild build specification
- Static output: HTML, CSS, JS files in `out/` directory

## Deployment

This application is deployed via:
1. Build: AWS CodeBuild (on LocalStack)
2. Deploy: AWS S3 static website hosting (on LocalStack)
3. Pipeline: AWS CodePipeline (on LocalStack)

See main README.md for full deployment instructions.

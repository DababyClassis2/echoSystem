import { cpSync, rmSync, mkdirSync, existsSync } from 'fs';
import { join, resolve } from 'path';

const distDir = resolve('dist');
const flutterAssetsDir = resolve('../assets/web');

try {
  // Clean old assets
  if (existsSync(flutterAssetsDir)) {
    rmSync(flutterAssetsDir, { recursive: true, force: true });
  }
  
  // Ensure directory exists
  mkdirSync(flutterAssetsDir, { recursive: true });

  // Copy build output
  cpSync(distDir, flutterAssetsDir, { recursive: true });
  
  console.log('✓ Web client build copied to Flutter assets/web');
} catch (err) {
  console.error('Error copying web client:', err);
  process.exit(1);
}

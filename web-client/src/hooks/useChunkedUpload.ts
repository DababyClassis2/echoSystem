import { useState, useCallback } from 'react';
import client from '../api/client';

export interface UploadState {
  fileName: string;
  progress: number;
  speed: string;
  eta: string;
  status: 'pending' | 'uploading' | 'completed' | 'error';
  error?: string;
}

const CHUNK_SIZE = 4 * 1024 * 1024; // 4MB

export const useChunkedUpload = () => {
  const [uploads, setUploads] = useState<Map<string, UploadState>>(new Map());

  const updateUpload = (id: string, update: Partial<UploadState>) => {
    setUploads((prev) => {
      const next = new Map(prev);
      const current = next.get(id) || { fileName: '', progress: 0, speed: '0 B/s', eta: '--', status: 'pending' };
      next.set(id, { ...current, ...update });
      return next;
    });
  };

  const uploadFile = useCallback(async (file: File, sessionId: string) => {
    const id = `${sessionId}-${file.name}`;
    updateUpload(id, { fileName: file.name, status: 'uploading', progress: 0 });

    try {
      // 1. HEAD request for resume offset
      let offset = 0;
      try {
        const headRes = await client.head('/files/upload-chunk', {
          headers: { 'X-Session-Id': sessionId, 'X-File-Name': file.name }
        });
        offset = parseInt(headRes.headers['x-received-bytes'] || '0');
      } catch (e) {
        offset = 0;
      }

      const total = file.size;
      const startTime = Date.now();

      while (offset < total) {
        const length = Math.min(CHUNK_SIZE, total - offset);
        const chunk = file.slice(offset, offset + length);
        
        let success = false;
        let retries = 0;

        while (!success && retries < 3) {
          try {
            await client.put('/files/upload-chunk', chunk, {
              headers: {
                'X-Session-Id': sessionId,
                'X-File-Name': file.name,
                'Content-Range': `bytes ${offset}-${offset + length - 1}/${total}`,
                'Content-Type': 'application/octet-stream'
              }
            });
            success = true;
          } catch (e) {
            retries++;
            if (retries >= 3) throw e;
            await new Promise(r => setTimeout(r, Math.pow(2, retries) * 1000));
          }
        }

        offset += length;
        const elapsed = (Date.now() - startTime) / 1000;
        const speedBps = offset / elapsed;
        const remaining = (total - offset) / speedBps;

        updateUpload(id, {
          progress: (offset / total) * 100,
          speed: speedBps > 1024 * 1024 
            ? `${(speedBps / (1024 * 1024)).toFixed(1)} MB/s` 
            : `${(speedBps / 1024).toFixed(1)} KB/s`,
          eta: remaining > 60 
            ? `${Math.floor(remaining / 60)}m ${Math.floor(remaining % 60)}s` 
            : `${Math.floor(remaining)}s`
        });
      }

      updateUpload(id, { status: 'completed', progress: 100 });
    } catch (e: any) {
      updateUpload(id, { status: 'error', error: e.message });
    }
  }, []);

  return { uploads, uploadFile };
};

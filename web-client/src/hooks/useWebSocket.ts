import { useState, useEffect, useCallback, useRef } from 'react';

export type ConnectionState = 'connected' | 'reconnecting' | 'disconnected';

export const useWebSocket = () => {
  const [lastEvent, setLastEvent] = useState<any>(null);
  const [connectionState, setConnectionState] = useState<ConnectionState>('disconnected');
  const ws = useRef<WebSocket | null>(null);
  const reconnectCount = useRef(0);

  const connect = useCallback(() => {
    const host = window.location.hostname;
    const url = `ws://${host}:8080/api/v1/ws`;
    
    setConnectionState(reconnectCount.current > 0 ? 'reconnecting' : 'disconnected');
    
    const socket = new WebSocket(url);

    socket.onopen = () => {
      console.log('WS Connected');
      setConnectionState('connected');
      reconnectCount.current = 0;
    };

    socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        setLastEvent(data);
      } catch (e) {
        console.error('WS Parse Error', e);
      }
    };

    socket.onclose = () => {
      setConnectionState('disconnected');
      const delay = Math.min(1000 * Math.pow(2, reconnectCount.current), 30000);
      reconnectCount.current++;
      setTimeout(connect, delay);
    };

    ws.current = socket;
  }, []);

  useEffect(() => {
    connect();
    return () => ws.current?.close();
  }, [connect]);

  return { lastEvent, connectionState };
};

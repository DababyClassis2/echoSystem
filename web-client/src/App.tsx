import React, { useState, useEffect } from 'react';
import { FileUp, HardDrive, Share2, Settings, Smartphone, Download, CheckCircle, AlertCircle, Loader2 } from 'lucide-react';
import client, { setPin } from './api/client';
import { useChunkedUpload } from './hooks/useChunkedUpload';
import { useWebSocket } from './hooks/useWebSocket';

const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'files' | 'devices' | 'transfers'>('files');
  const [files, setFiles] = useState<any[]>([]);
  const [devices, setDevices] = useState<any[]>([]);
  const [pin, setPinState] = useState('');
  const [isAuthRequired, setIsAuthRequired] = useState(false);
  
  const { uploads, uploadFile } = useChunkedUpload();
  const { lastEvent, connectionState } = useWebSocket();

  useEffect(() => {
    const handleAuth = () => setIsAuthRequired(true);
    window.addEventListener('ls:auth-required', handleAuth);
    return () => window.removeEventListener('ls:auth-required', handleAuth);
  }, []);

  useEffect(() => {
    fetchFiles();
    fetchDevices();
  }, []);

  useEffect(() => {
    if (lastEvent?.type === 'FILE_RECEIVED') fetchFiles();
    if (lastEvent?.type === 'DEVICE_JOINED') fetchDevices();
  }, [lastEvent]);

  const fetchFiles = async () => {
    try {
      const res = await client.get('/files');
      setFiles(res.data);
    } catch (e) {}
  };

  const fetchDevices = async () => {
    try {
      const res = await client.get('/devices');
      setDevices(res.data);
    } catch (e) {}
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const sessionId = Date.now().toString();
      Array.from(e.target.files).forEach(file => uploadFile(file, sessionId));
    }
  };

  return (
    <div className="min-h-screen bg-[#0A0A0F] text-[#E0E0E0] font-sans">
      {/* Header */}
      <header className="p-4 bg-[#141420] border-b border-white/10 flex justify-between items-center">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-[#00D4FF] flex items-center justify-center">
            <Share2 className="text-black" size={18} />
          </div>
          <h1 className="text-lg font-bold tracking-tight">LocalShare Web</h1>
        </div>
        <div className={`px-2 py-1 rounded text-[10px] font-bold uppercase ${
          connectionState === 'connected' ? 'bg-green-500/20 text-green-500' : 'bg-red-500/20 text-red-500'
        }`}>
          {connectionState}
        </div>
      </header>

      {/* Main Content */}
      <main className="p-4 pb-24">
        {activeTab === 'files' && (
          <div className="space-y-6">
            <label className="block p-8 border-2 border-dashed border-white/10 rounded-2xl bg-[#141420] hover:border-[#00D4FF]/50 transition-colors text-center cursor-pointer">
              <input type="file" multiple className="hidden" onChange={handleFileUpload} />
              <FileUp className="mx-auto text-[#00D4FF] mb-2" size={32} />
              <p className="font-medium">Click to upload or drag files</p>
              <p className="text-xs text-gray-500 mt-1">Files saved to Android device</p>
            </label>

            <div className="grid grid-cols-2 gap-4">
              {files.map((file, i) => (
                <div key={i} className="p-3 bg-[#141420] rounded-xl border border-white/5 space-y-2">
                  <div className="w-10 h-10 rounded-lg bg-white/5 flex items-center justify-center">
                    <Download size={20} />
                  </div>
                  <div className="overflow-hidden">
                    <p className="text-sm font-medium truncate">{file.name}</p>
                    <p className="text-[10px] text-gray-500 font-mono">{file.size} bytes</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {activeTab === 'devices' && (
          <div className="space-y-4">
            {devices.map((device, i) => (
              <div key={i} className="p-4 bg-[#141420] rounded-xl flex items-center gap-4">
                <div className="w-12 h-12 rounded-full bg-white/5 flex items-center justify-center">
                  <Smartphone size={24} />
                </div>
                <div>
                  <p className="font-bold">{device.deviceName}</p>
                  <p className="text-xs font-mono text-[#00D4FF]">{device.ip}</p>
                </div>
              </div>
            ))}
            {devices.length === 0 && (
              <div className="text-center py-12 text-gray-500">
                <Loader2 className="mx-auto mb-2 animate-spin" />
                <p>Waiting for devices...</p>
              </div>
            )}
          </div>
        )}

        {activeTab === 'transfers' && (
          <div className="space-y-3">
            {Array.from(uploads.values()).map((u, i) => (
              <div key={i} className="p-4 bg-[#141420] rounded-xl space-y-3">
                <div className="flex justify-between items-center">
                  <p className="text-xs font-medium truncate max-w-[60%]">{u.fileName}</p>
                  <p className="text-[10px] font-mono text-[#00D4FF]">{u.speed}</p>
                </div>
                <div className="h-1.5 bg-white/5 rounded-full overflow-hidden">
                  <div 
                    className="h-full bg-[#00D4FF] transition-all duration-300" 
                    style={{ width: `${u.progress}%` }}
                  />
                </div>
                <div className="flex justify-between text-[10px] text-gray-500">
                  <span>{u.status}</span>
                  <span>ETA: {u.eta}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>

      {/* Navigation */}
      <nav className="fixed bottom-0 left-0 right-0 bg-[#141420] border-t border-white/10 p-2 flex justify-around">
        <NavButton active={activeTab === 'files'} onClick={() => setActiveTab('files')} icon={<HardDrive />} label="Files" />
        <NavButton active={activeTab === 'devices'} onClick={() => setActiveTab('devices')} icon={<Smartphone />} label="Devices" />
        <NavButton active={activeTab === 'transfers'} onClick={() => setActiveTab('transfers')} icon={<Share2 />} label="Transfers" />
      </nav>

      {/* Auth Modal */}
      {isAuthRequired && (
        <div className="fixed inset-0 bg-black/80 flex items-center justify-center p-6 z-50">
          <div className="bg-[#141420] p-8 rounded-3xl w-full max-w-sm space-y-6 border border-white/10">
            <div className="text-center">
              <h2 className="text-xl font-bold">Authentication Required</h2>
              <p className="text-sm text-gray-400 mt-2">Enter the 4-digit PIN shown on the device</p>
            </div>
            <input 
              type="text" 
              maxLength={4} 
              className="w-full bg-black/20 border border-white/10 rounded-xl p-4 text-center text-2xl font-mono tracking-widest focus:border-[#00D4FF] outline-none"
              value={pin}
              onChange={(e) => {
                setPinState(e.target.value);
                if (e.target.value.length === 4) {
                  setPin(e.target.value);
                  setIsAuthRequired(false);
                  window.location.reload();
                }
              }}
            />
          </div>
        </div>
      )}
    </div>
  );
};

const NavButton = ({ active, onClick, icon, label }: any) => (
  <button 
    onClick={onClick}
    className={`flex flex-col items-center gap-1 p-2 transition-colors ${active ? 'text-[#00D4FF]' : 'text-gray-500'}`}
  >
    {React.cloneElement(icon, { size: 20 })}
    <span className="text-[10px] font-medium">{label}</span>
  </button>
);

export default App;

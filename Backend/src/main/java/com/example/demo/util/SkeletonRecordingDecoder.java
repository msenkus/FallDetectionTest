package com.example.demo.util;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.*;

public class SkeletonRecordingDecoder {
    
    public static Map<String, Object> decode(String base64Data) {
        try {
            byte[] binaryData = Base64.getDecoder().decode(base64Data);
            System.out.println("🎬 Decoding " + binaryData.length + " bytes");
            
            ByteBuffer buffer = ByteBuffer.wrap(binaryData);
            buffer.order(ByteOrder.LITTLE_ENDIAN);
            
            // Version 3 Format: Different header structure
            // Bytes 0-3: Version (uint32)
            int version = buffer.getInt();
            System.out.println("📋 Version: " + version);
            
            if (version != 3) {
                System.out.println("⚠️ Unsupported version: " + version);
                return createEmptyResult();
            }
            
            // Bytes 4-7: Alert ID or timestamp related
            long alertId = buffer.getInt() & 0xFFFFFFFFL;
            // Bytes 8-11: Camera ID (0xFFFFFFFE = -2 unsigned)
            long cameraId = buffer.getInt() & 0xFFFFFFFFL;
            // Bytes 12-15: Timestamp or other metadata
            long metadata = buffer.getInt() & 0xFFFFFFFFL;
            
            System.out.println("📋 alertId=" + alertId + ", cameraId=" + cameraId + ", metadata=" + metadata);
            
            List<Map<String, Object>> frames = new ArrayList<>();
            int frameIdx = 0;
            
            // Version 3: No frame count in header, parse until end of buffer
            while (buffer.remaining() >= 4 && frameIdx < 1000) {
                int deltaTime = buffer.getShort() & 0xFFFF;
                int numPeople = buffer.getShort() & 0xFFFF;
                
                System.out.println("📹 Frame " + frameIdx + ": deltaTime=" + deltaTime + ", people=" + numPeople);
                
                if (numPeople > 20 || numPeople < 0) {
                    System.out.println("⚠️ Frame " + frameIdx + " claims " + numPeople + " people (suspicious), stopping");
                    break;
                }
                
                if (buffer.remaining() < numPeople * 16) {
                    System.out.println("⚠️ Not enough data for " + numPeople + " people, stopping");
                    break;
                }
                
                List<List<List<Double>>> people = new ArrayList<>();
                
                for (int personIdx = 0; personIdx < numPeople; personIdx++) {
                    if (buffer.remaining() < 16) break;
                    
                    // Person header (16 bytes)
                    int personId = buffer.getInt();
                    int trackerId = buffer.get() & 0xFF;
                    int numKeypoints = buffer.get() & 0xFF;
                    int event = buffer.get() & 0xFF;
                    int actionLabel = buffer.get() & 0xFF;
                    long probabilities = buffer.getLong();
                    
                    if (numKeypoints > 25) {
                        System.out.println("⚠️ Person " + personIdx + " claims " + numKeypoints + " keypoints (too many), skipping");
                        continue;
                    }
                    
                    // Initialize 18 keypoints to (0,0)
                    List<List<Double>> keypoints = new ArrayList<>();
                    for (int i = 0; i < 18; i++) {
                        keypoints.add(Arrays.asList(0.0, 0.0));
                    }
                    
                    // Read actual keypoints (6 bytes each)
                    for (int kpIdx = 0; kpIdx < numKeypoints; kpIdx++) {
                        if (buffer.remaining() < 6) break;
                        
                        int descriptor = buffer.get() & 0xFF;
                        int probability = buffer.get() & 0xFF;
                        int xRaw = buffer.getShort() & 0xFFFF;
                        int yRaw = buffer.getShort() & 0xFFFF;
                        
                        int keypointIndex = descriptor & 0x1F;
                        double x = xRaw / 65536.0;
                        double y = yRaw / 65536.0;
                        
                        if (keypointIndex < 18 && x > 0 && y > 0 && x <= 1.0 && y <= 1.0) {
                            keypoints.set(keypointIndex, Arrays.asList(x, y));
                        }
                    }
                    
                    people.add(keypoints);
                }
                
                Map<String, Object> frame = new HashMap<>();
                frame.put("frameNum", frameIdx);
                frame.put("deltaTime", deltaTime);
                frame.put("numPeople", people.size());
                frame.put("people", people);
                frames.add(frame);
                
                frameIdx++;
            }
            
            System.out.println("✅ Decoded " + frames.size() + " frames");
            
            Map<String, Object> result = new HashMap<>();
            result.put("totalFrames", frames.size());
            result.put("frames", frames);
            
            // Backward compatibility: include first frame data at top level
            if (!frames.isEmpty()) {
                Map<String, Object> first = frames.get(0);
                result.put("frameNum", 0);
                result.put("numPeople", first.get("numPeople"));
                result.put("people", first.get("people"));
            } else {
                result.put("frameNum", 0);
                result.put("numPeople", 0);
                result.put("people", new ArrayList<>());
            }
            
            return result;
            
        } catch (Exception e) {
            System.err.println("❌ Error: " + e.getMessage());
            e.printStackTrace();
            return createEmptyResult();
        }
    }
    
    private static Map<String, Object> createEmptyResult() {
        Map<String, Object> result = new HashMap<>();
        result.put("totalFrames", 0);
        result.put("frames", new ArrayList<>());
        result.put("frameNum", 0);
        result.put("numPeople", 0);
        result.put("people", new ArrayList<>());
        return result;
    }
}

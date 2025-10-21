package com.example.demo.util;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.*;

/**
 * Decoder for AltumView MQTT skeleton binary format
 * Based on the MQTT protocol specification from the Flutter MQTT service
 */
public class SkeletonDecoder {
    
    /**
     * Decode binary skeleton data to JSON format
     * 
     * Binary format (from official AltumView example):
     * - frameNum (int32, 4 bytes at offset 0)
     * - numPeople (int32, 4 bytes at offset 4)
     * - For each person (152 bytes):
     *   - personId (int32, 4 bytes)
     *   - 18 X coordinates (float32, 72 bytes) - NORMALIZED 0.0-1.0
     *   - 18 Y coordinates (float32, 72 bytes) - NORMALIZED 0.0-1.0
     *   - padding (4 bytes)
     * 
     * @param base64Data Base64-encoded binary skeleton data
     * @return Map with "people" array containing skeleton keypoints (normalized 0-1)
     */
    public static Map<String, Object> decode(String base64Data) {
        try {
            // Decode base64
            byte[] binaryData = Base64.getDecoder().decode(base64Data);
            
            ByteBuffer buffer = ByteBuffer.wrap(binaryData);
            buffer.order(ByteOrder.LITTLE_ENDIAN);
            
            // Read frame number (offset 0)
            int frameNum = buffer.getInt();
            
            // Read number of people (offset 4)
            int numPeople = buffer.getInt();
            
            List<List<List<Double>>> people = new ArrayList<>();
            List<Integer> personIds = new ArrayList<>();
            
            if (numPeople == 0) {
                Map<String, Object> result = new HashMap<>();
                result.put("frameNum", frameNum);
                result.put("people", people);
                return result;
            }
            
            // Parse each person (152 bytes each, starting at offset 8)
            for (int i = 0; i < numPeople; i++) {
                int personPos = 8 + (152 * i);
                
                // Check if we have enough data
                if (personPos + 152 > binaryData.length) {
                    break;
                }
                
                // Read person ID
                buffer.position(personPos);
                int personId = buffer.getInt();
                personIds.add(personId);
                
                // Read X coordinates (18 floats starting at personPos + 8)
                float[] xCoords = new float[18];
                buffer.position(personPos + 8);
                for (int j = 0; j < 18; j++) {
                    xCoords[j] = buffer.getFloat();
                }
                
                // Read Y coordinates (18 floats starting at personPos + 80)
                // 80 = 8 (personId offset) + 72 (18 floats * 4 bytes)
                float[] yCoords = new float[18];
                buffer.position(personPos + 80);
                for (int j = 0; j < 18; j++) {
                    yCoords[j] = buffer.getFloat();
                }
                
                // Create keypoints array
                List<List<Double>> keypoints = new ArrayList<>();
                for (int j = 0; j < 18; j++) {
                    // Coordinates are already normalized 0.0-1.0
                    // Include all keypoints, even if zero (frontend will handle)
                    keypoints.add(Arrays.asList((double) xCoords[j], (double) yCoords[j]));
                }
                
                people.add(keypoints);
            }
            
            Map<String, Object> result = new HashMap<>();
            result.put("frameNum", frameNum);
            result.put("numPeople", numPeople);
            result.put("personIds", personIds);
            result.put("people", people);
            
            return result;
            
        } catch (Exception e) {
            throw new RuntimeException("Failed to decode skeleton data: " + e.getMessage(), e);
        }
    }
    
    /**
     * Get keypoint names for OpenPose 18-point format
     */
    public static List<String> getKeypointNames() {
        return Arrays.asList(
            "Nose",           // 0
            "Neck",           // 1
            "RShoulder",      // 2
            "RElbow",         // 3
            "RWrist",         // 4
            "LShoulder",      // 5
            "LElbow",         // 6
            "LWrist",         // 7
            "RHip",           // 8
            "RKnee",          // 9
            "RAnkle",         // 10
            "LHip",           // 11
            "LKnee",          // 12
            "LAnkle",         // 13
            "REye",           // 14
            "LEye",           // 15
            "REar",           // 16
            "LEar"            // 17
        );
    }
}

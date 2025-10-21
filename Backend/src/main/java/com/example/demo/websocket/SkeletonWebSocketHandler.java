package com.example.demo.websocket;

import com.example.demo.service.AltumViewService;
import com.example.demo.model.MqttCredentials;
import com.example.demo.model.StreamToken;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.eclipse.paho.client.mqttv3.*;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.*;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.nio.ByteBuffer;
import java.util.Base64;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@Component
public class SkeletonWebSocketHandler extends TextWebSocketHandler {
    
    private static final Logger logger = LoggerFactory.getLogger(SkeletonWebSocketHandler.class);
    
    private final AltumViewService altumViewService;
    private final ObjectMapper objectMapper;
    private final Map<String, WebSocketSession> sessions = new ConcurrentHashMap<>();
    private final Map<String, MqttClient> mqttClients = new ConcurrentHashMap<>();
    private final Map<String, ScheduledExecutorService> tokenRefreshers = new ConcurrentHashMap<>();
    
    public SkeletonWebSocketHandler(AltumViewService altumViewService) {
        this.altumViewService = altumViewService;
        this.objectMapper = new ObjectMapper();
    }
    
    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        sessions.put(session.getId(), session);
        logger.info("WebSocket connected: {}", session.getId());
    }
    
    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        try {
            JsonNode msg = objectMapper.readTree(message.getPayload());
            String action = msg.get("action").asText();
            
            if ("connect".equals(action)) {
                String cameraSerialNumber = msg.get("cameraSerialNumber").asText();
                connectToMqtt(session, cameraSerialNumber);
            } else if ("disconnect".equals(action)) {
                disconnectFromMqtt(session.getId());
            }
        } catch (Exception e) {
            logger.error("Error handling WebSocket message", e);
            sendError(session, "Error: " + e.getMessage());
        }
    }
    
    private void connectToMqtt(WebSocketSession session, String cameraSerialNumber) {
        try {
            // Get MQTT credentials and stream token
            MqttCredentials credentials = altumViewService.getMqttCredentials();
            StreamToken streamToken = altumViewService.getStreamToken(cameraSerialNumber);
            
            logger.info("Connecting to MQTT for camera {} on session {}", cameraSerialNumber, session.getId());
            
            // Create MQTT client
            String clientId = "backend_" + session.getId().substring(0, 8);
            MqttClient mqttClient = new MqttClient(
                credentials.getWssUrl().replace("wss://", "ssl://"), // Paho uses ssl:// for secure connections
                clientId,
                new MemoryPersistence()
            );
            
            // Configure MQTT connection options
            MqttConnectOptions options = new MqttConnectOptions();
            options.setUserName(credentials.getUsername());
            options.setPassword(credentials.getPassword().toCharArray());
            options.setCleanSession(true);
            options.setAutomaticReconnect(true);
            options.setConnectionTimeout(10);
            options.setKeepAliveInterval(20);
            
            // Set callback for incoming messages
            mqttClient.setCallback(new MqttCallback() {
                @Override
                public void connectionLost(Throwable cause) {
                    logger.warn("MQTT connection lost for session {}", session.getId(), cause);
                    sendError(session, "MQTT connection lost");
                }
                
                @Override
                public void messageArrived(String topic, MqttMessage message) {
                    try {
                        // Forward binary message to WebSocket client as base64
                        byte[] payload = message.getPayload();
                        String base64Data = Base64.getEncoder().encodeToString(payload);
                        
                        if (session.isOpen()) {
                            session.sendMessage(new TextMessage(objectMapper.writeValueAsString(
                                Map.of(
                                    "type", "skeleton_data",
                                    "data", base64Data
                                )
                            )));
                        }
                    } catch (Exception e) {
                        logger.error("Error forwarding MQTT message", e);
                    }
                }
                
                @Override
                public void deliveryComplete(IMqttDeliveryToken token) {
                    // Not used for subscriptions
                }
            });
            
            // Connect to MQTT broker
            mqttClient.connect(options);
            logger.info("MQTT connected for session {}", session.getId());
            
            // Subscribe to skeleton data topic
            mqttClient.subscribe(streamToken.getSubscribeTopic(), 0);
            logger.info("Subscribed to topic: {}", streamToken.getSubscribeTopic());
            
            // Publish initial stream token
            publishStreamToken(mqttClient, streamToken);
            
            // Schedule token refresh every 45 seconds
            ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();
            scheduler.scheduleAtFixedRate(() -> {
                try {
                    StreamToken newToken = altumViewService.getStreamToken(cameraSerialNumber);
                    publishStreamToken(mqttClient, newToken);
                    logger.debug("Refreshed stream token for session {}", session.getId());
                } catch (Exception e) {
                    logger.error("Error refreshing stream token", e);
                }
            }, 45, 45, TimeUnit.SECONDS);
            
            // Store references
            mqttClients.put(session.getId(), mqttClient);
            tokenRefreshers.put(session.getId(), scheduler);
            
            // Send success message
            session.sendMessage(new TextMessage(objectMapper.writeValueAsString(
                Map.of("type", "connected", "camera", cameraSerialNumber)
            )));
            
        } catch (Exception e) {
            logger.error("Error connecting to MQTT", e);
            sendError(session, "Failed to connect: " + e.getMessage());
        }
    }
    
    private void publishStreamToken(MqttClient mqttClient, StreamToken streamToken) {
        try {
            MqttMessage message = new MqttMessage(streamToken.getToken().getBytes());
            message.setQos(0);
            mqttClient.publish(streamToken.getPublishTopic(), message);
        } catch (Exception e) {
            logger.error("Error publishing stream token", e);
        }
    }
    
    private void disconnectFromMqtt(String sessionId) {
        try {
            // Stop token refresher
            ScheduledExecutorService scheduler = tokenRefreshers.remove(sessionId);
            if (scheduler != null) {
                scheduler.shutdown();
            }
            
            // Disconnect MQTT client
            MqttClient mqttClient = mqttClients.remove(sessionId);
            if (mqttClient != null && mqttClient.isConnected()) {
                mqttClient.disconnect();
                mqttClient.close();
                logger.info("MQTT disconnected for session {}", sessionId);
            }
        } catch (Exception e) {
            logger.error("Error disconnecting MQTT", e);
        }
    }
    
    private void sendError(WebSocketSession session, String error) {
        try {
            if (session.isOpen()) {
                session.sendMessage(new TextMessage(objectMapper.writeValueAsString(
                    Map.of("type", "error", "message", error)
                )));
            }
        } catch (Exception e) {
            logger.error("Error sending error message", e);
        }
    }
    
    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        String sessionId = session.getId();
        disconnectFromMqtt(sessionId);
        sessions.remove(sessionId);
        logger.info("WebSocket disconnected: {}", sessionId);
    }
    
    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) {
        logger.error("WebSocket transport error for session {}", session.getId(), exception);
        disconnectFromMqtt(session.getId());
    }
}

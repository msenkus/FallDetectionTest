# 🚀 Quick Start - Run the System

## Start Backend
```bash
cd /Users/marksenkus/Documents/Projects/FallDetectionTest/Backend
java -jar target/demo-0.0.1-SNAPSHOT.jar
```

## Start Frontend
```bash
cd /Users/marksenkus/Documents/Projects/FallDetectionTest/Frontend
flutter run -d chrome
```

## Verify Working
```bash
# Test backend
curl http://localhost:8080/api/skeleton/alerts/68f166168eeae9e50d48e58a/skeleton-decoded

# Should return JSON with skeleton data
```

## What to Expect
1. ✅ Alerts screen loads with test alert
2. ✅ Click alert to see skeleton visualization
3. ✅ Skeleton shows person in fall position (mock data)
4. ✅ No errors in console

## If Issues
```bash
# Kill and restart backend
lsof -ti:8080 | xargs kill -9
cd Backend && java -jar target/demo-0.0.1-SNAPSHOT.jar

# Restart Flutter
# Press 'r' in terminal for hot reload
# Press 'R' for full restart
```

---

**Status:** ✅ System Ready  
**Documentation:** See `FINAL_WORKING_STATUS.md`

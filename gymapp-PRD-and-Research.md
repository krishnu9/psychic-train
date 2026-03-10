# **Strategic Product Requirements and Technical Architecture for an Advanced Strength Training Tracking Ecosystem**

The digital transformation of strength training has evolved from simple spreadsheet replicas into sophisticated analytical engines that interface with biological data streams. In the modern fitness landscape, specifically looking toward 2025 and 2026, the value of a workout tracking application is no longer found in its ability to merely record data points but in its capacity to interpret those points to drive physiological adaptation. The principle of progressive overload—the gradual increase of stress placed upon the body—remains the bedrock of muscular hypertrophy and strength gains.1 However, the human error inherent in manual tracking, combined with the cognitive load of high-intensity exercise, creates a significant demand for a specialized digital intermediary that manages the complexities of programming, execution, and historical analysis.

The proposed application architecture addresses the fundamental requirements of exercise management and routine orchestration while anticipating the needs of elite athletes and casual gym-goers alike. By structuring the product around the atomic units of "Exercises" and the grouped templates of "Routines," the system provides a hierarchical framework that mirrors the actual workflow of a trainee: preparing a plan, executing that plan in the gym, and logging performance metrics such as sets, weights, and repetitions in real-time.3

## **Competitive Landscape and Market Benchmarking**

Before defining the specific requirements for a new tracking solution, an analysis of the existing market leaders provides essential context regarding user expectations and feature gaps. The current ecosystem is dominated by a few key players, each prioritizing different aspects of the lifting experience, such as speed, social connectivity, or extensive databases.5

### **Feature Comparison of Market Leaders**

The following table summarizes the core strengths and limitations of established applications as of 2025 and 2026, serving as a baseline for the development of a superior tracking tool.

| App Name | Core Value Proposition | Free Tier Limitations | Premium Price (Approx.) | Notable Feature |
| :---- | :---- | :---- | :---- | :---- |
| **Strong** | Minimalist efficiency for experienced lifters.5 | Limited to 3 routines; no advanced charts.6 | $4.99/mo or $29.99/yr.5 | Automatic rest timers and plate calculator.5 |
| **Hevy** | Social motivation and community-based routine sharing.10 | Generous; allows more routines than Strong.6 | $2.99/mo or $23.99/yr.10 | Social feed and Wear OS integration.5 |
| **JEFIT** | Massive exercise library with video demonstrations.6 | Ad-supported; interface can feel cluttered.6 | $12.99/mo or $69.99/yr.5 | 1,400+ exercises with 3D muscle maps.5 |
| **Fitbod** | AI-generated workouts based on equipment and fatigue.9 | 7-day trial; no functional free tier.8 | $15.99/mo or $95.99/yr.9 | Adaptive programming based on muscle soreness.9 |
| **Setgraph** | High-speed logging for non-linear training styles.11 | 5-day trial period.5 | Annual or lifetime subscription.5 | Swipe-to-record and "Notepad mode".5 |

The analysis indicates a clear divergence in philosophy. "Tracking-focused" tools like Strong and Hevy prioritize the manual entry of sets and reps for self-designed routines, while "AI-powered" tools like Fitbod attempt to replace the trainer by generating the program itself.9 The proposed application aims to capture the "middle-ground" user who knows their routine—such as a classic "Push/Pull/Legs" or "Chest Day" split—but requires a high-performance logging interface that automates the math of progressive overload.2

## **Product Requirements Document (PRD): Core Functional Framework**

The Product Requirements Document (PRD) serves as the definitive guide for the engineering and design teams. It outlines what the product should do from a functional perspective and establishes the success criteria for the initial release.14

### **Executive Summary and Strategic Purpose**

The primary problem this application solves is "logging friction"—the mental and physical effort required to track a workout while in a state of physical exertion. Many trainees abandon logging because the interface is too cumbersome or requires too many taps.16 The strategic purpose is to provide an "offline-first" digital logbook that pre-fills data, manages rest intervals, and calculates strength trends automatically, allowing the user to focus entirely on the physical execution of the exercise.11

### **User Profiles and Target Personas**

| User Persona | Goals | Pain Points |
| :---- | :---- | :---- |
| **The Structured Athlete** | Execute a 12-week powerlifting block with precision. | Needs to see previous set data instantly without navigation.5 |
| **The Data-Driven Bodybuilder** | Track volume per muscle group to optimize hypertrophy. | Manual volume calculation is tedious and prone to error.19 |
| **The Busy Professional** | Complete a 45-minute workout with zero distractions. | Doesn't want to spend more than 10 seconds logging per set.16 |
| **The Community Motivator** | Share progress and compete with gym partners. | Training alone leads to stagnation and loss of motivation.20 |

### **Functional Requirements: Movement and Routine Management**

The core of the application is built on the relationship between an exercise library and routine templates. Users must be able to organize their training into logical groups that reflect common fitness splits.3

#### **Exercise Library and Movement Database**

The application must support a vast array of exercises including compound movements like the bench press, shoulder press, and squat, as well as isolation movements like lateral raises \[User Query\]. Each movement entry requires specific metadata to support later analysis.3

* **Category and Muscle Group**: Exercises must be categorized by primary muscle (e.g., Quads, Pectorals) and equipment type (e.g., Barbell, Dumbbell, Machine).3  
* **Multimedia Guidance**: Integration of animations or videos to demonstrate proper form, which is critical for injury prevention and beginner guidance.5  
* **Custom Exercises**: Users must have the ability to create their own exercises, specifying the name and category, ensuring the tool accommodates niche or unconventional movements.4

#### **Routine Orchestration**

Routines act as reusable templates. A user might create a "Leg Day" routine consisting of squats, lunges, and calf raises.4

* **Template Logic**: A routine allows the user to pre-define the sequence of exercises and set target values for sets, repetitions, and weights.5  
* **Routine Diversity**: Support for various split styles, including Body Part Splits (e.g., Chest Day), Push/Pull/Legs, and Full Body routines.24  
* **Copy and Modify**: The ability to duplicate an existing routine to create a variation, such as "Leg Day \- Heavy" vs. "Leg Day \- Volume".4

### **Functional Requirements: The Active Workout Workflow**

The application’s success is defined by the "Gym Mode"—the state where the user is actively lifting and needs to record data as quickly as possible.17

#### **Starting a Session**

When the user enters the gym, the application presents a list of available routines. Upon selecting a routine, the app should instantly load the corresponding exercises.6

* **Routine Pre-fill**: The interface displays all exercises in the pre-defined order, showing the last performed weight and reps for each as a reference point.5  
* **Ad-hoc Adjustments**: While in the middle of a workout, users must be able to swap an exercise (e.g., if a machine is occupied), delete an exercise, or add an extra movement on the fly.4

#### **Logging Sets and Reps**

Every set performed requires the logging of three primary variables: weight, reps, and the specific set number.3

* **One-Tap Completion**: A large, thumb-accessible "Check" button to mark a set as complete.11  
* **Automatic Rest Timer**: Upon completion of a set, a countdown timer should start automatically to ensure consistent rest intervals, which is a key driver for both strength and hypertrophy.5  
* **Set Tagging**: The ability to mark a set as a "Warm-up," "Failure," or "Drop Set" to ensure volume metrics are calculated correctly.12  
* **Notes and RPE**: Users should be able to add per-set or per-exercise notes (e.g., "Left shoulder felt tight") and input a Rate of Perceived Exertion (RPE) score to track intensity.2

### **Success Metrics and Performance Indicators**

The effectiveness of the PRD is measured through Key Performance Indicators (KPIs) that track user engagement and product stability.14

| Metric | Target Goal | Rationale |
| :---- | :---- | :---- |
| **Time-to-Start** | \< 10 seconds | Users should be able to start their workout almost immediately upon arrival.16 |
| **Session Completion Rate** | \> 85% | Indicates that the tracking process is not so burdensome that users quit midway. |
| **Daily Active Users (DAU)** | Growth trend | Reflects the habit-forming nature of the tracking tool.15 |
| **Crash-Free Sessions** | 99.9% | Critical for maintaining trust, as data loss during a workout is a primary cause for churn.29 |
| **Retention (Month 1\)** | \> 40% | Measures the long-term value provided by the progress tracking visualizations.15 |

## **Data Architecture: Relational Modeling for Strength Training**

A robust backend is the backbone of any tracking application, ensuring data consistency and efficient query performance across thousands of workout logs.3 The architecture must distinguish between "Templates" (what is planned) and "Logs" (what was actually done).4

### **Core Entity Relationships**

The following schema represents the primary entities required to support the user's requested workflow. This design ensures that a single exercise can belong to multiple routines and that many workout instances can be derived from one routine template.3

| Entity Name | Description | Key Attributes | Relationships |
| :---- | :---- | :---- | :---- |
| **User** | The central profile for an athlete.3 | UserID, Email, WeightUnits (kg/lbs), BodyWeight, Goal.21 | One-to-Many: Routines, Workouts. |
| **Exercise** | The static library of all possible movements.21 | ExerciseID, Name, Category, TargetMuscles, VideoURL.3 | Many-to-Many: Routines (via RoutineExercise), Sets. |
| **Routine** | A pre-defined collection of exercises (e.g., "Push Day").4 | RoutineID, UserID, Name, DayOfWeek, Description.4 | One-to-Many: RoutineExercises. |
| **RoutineExercise** | The join table defining the order and targets for a specific routine.4 | RoutineExID, RoutineID, ExerciseID, DisplayOrder, TargetSets.4 | Connects Exercise to Routine. |
| **Workout** | An instance of a completed training session on a specific date.3 | WorkoutID, UserID, RoutineID (Optional), Date, Duration, TotalVolume.3 | One-to-Many: LoggedSets. |
| **LoggedSet** | The atomic record of performance for one exercise during a workout.22 | SetID, WorkoutID, ExerciseID, Weight, Reps, RPE, RestSeconds.21 | Belongs to Workout and Exercise. |

### **The "Single Source of Truth" and Data Normalization**

To optimize performance and usability, the architecture avoids unnecessary duplication. For instance, if a user changes the equipment type for "Bench Press" in the master exercise table, that change should propagate across all routines that include that exercise.22 The use of pointers ensures that the application can efficiently retrieve a user's entire lifting history for a specific movement, regardless of which routine it was performed in—a feature known as "Exercise-centric architecture".3

## **User Experience Engineering: Designing for the "Thumb Zone"**

High-intensity weightlifting environments introduce physical constraints that must be accounted for in UI/UX design. When an athlete is mid-workout, their fine motor skills are often impaired due to fatigue, and their attention is fragmented.16

### **The Thumb Zone and Reachability**

Mobile interaction research demonstrates that users primarily interact with their devices using one hand, especially when multi-tasking in a gym.25

* **The Bottom Third Priority**: The bottom third of the smartphone screen is the "Easy Zone," where the thumb rests naturally. Critical buttons such as "Log Set," "Start Workout," and "Add Exercise" must be placed here.25  
* **The Stretch Zone**: The middle portion of the screen should be used for secondary navigation, such as scrolling through the list of exercises in a routine.26  
* **The Impossible Zone**: The top corners are the "Death Zones," which require a grip adjustment to reach. These areas are reserved for infrequent, non-urgent actions like "Settings" or "User Profile".26

### **Flow-Friendly Workout Interfaces**

A "Flow-Friendly" interface minimizes cognitive load and keeps the user in the "mental zone" where their best performance occurs.11

* **One Action Per Screen**: Each screen should focus on a single goal—either viewing the routine list or logging a set. This reduces clutter and distraction.16  
* **Smart Plate Calculator**: Calculating the weight for a 125 kg barbell squat involves mental math that can be taxing. A visual plate calculator showing exactly which plates to load (e.g., two 20s, one 10, one 2.5 on each side) provides immediate utility.5  
* **Notepad Mode**: A feature that keeps the screen awake and the brightness adjusted during the workout, ensuring the user can log their next set without having to unlock their phone with sweaty hands.5  
* **Audio and Haptic Cues**: Subtle vibrations or sounds to signify the end of a rest timer or the successful completion of a set allow the user to keep their phone in their pocket or on a nearby bench without constant visual monitoring.16

## **Algorithmic Intelligence: Quantifying the Progressive Overload Principle**

The primary goal of tracking is to manage "Progressive Overload"—the strategic enhancement of resistance or intensity over time to compel the body to adapt.13 The application should not just store numbers; it should apply mathematical models to those numbers to provide actionable feedback.13

### **Estimating Maximal Strength (1RM)**

To prescribe intensity accurately, the application needs to calculate the user's "One-Rep Max" (1RM)—the maximum weight they can lift for a single repetition.33 Since testing an actual 1RM is physically demanding and risky, estimation formulas are used.33

The system should implement several scientifically validated formulas to ensure accuracy across different rep ranges 33:

* **Brzycki Formula (Optimal for 1-7 reps)**:  
  ![][image1]  
  This formula is the industry standard for strength sports and powerlifting.33  
* **Epley Formula (Optimal for 8-15 reps)**:  
  ![][image2]  
  The Epley formula is more conservative and better suited for hypertrophy-focused training.33

By averaging these results (and potentially Wathan's formula), the application provides a robust estimate that limits the impact of individual physiological variations.33

### **Auto-Regulation through RPE and RIR**

Strength performance fluctuates daily based on external stressors like sleep, nutrition, and work stress.27 "Auto-regulation" is the practice of adjusting the daily load based on "Daily Readiness".27

The application should integrate the Rate of Perceived Exertion (RPE) scale, specifically the 0-10 category-ratio scale.37

| RPE Score | Meaning | Repetitions in Reserve (RIR) |
| :---- | :---- | :---- |
| **10** | Maximum Effort | 0 reps left.27 |
| **9** | Very Hard | 1 rep left.27 |
| **8** | Hard | 2 reps left.27 |
| **7** | Vigorous | 3 reps left.27 |
| **6** | Moderate | 4-6 reps left.38 |

Using this logic, the application can suggest weights for the next set. For example, if a user performed 100 kg for 5 reps and rated it an RPE 7 (3 reps left), the app can calculate that their 1RM is approximately 120 kg and suggest 105 kg for the next set to achieve a target RPE of 8\.27

## **Technical Architecture: Offline-First and Wearable Synergy**

A workout tracking app that fails because the gym is in a concrete basement with no Wi-Fi is essentially useless.40 Therefore, an "Offline-First" strategy is a foundational requirement, not a luxury.18

### **Robust Local Data Persistence**

The mobile device must serve as the "Single Source of Truth" while the user is in the gym. The UI should always read from and write to a local database (e.g., SQLite, Room, or Core Data) rather than waiting for an API response.18

* **Background Sync Engine**: Changes are committed locally first, and a background process syncs them with the server once connectivity is restored.18  
* **Optimistic UI Patterns**: The application immediately reflects user actions—like completing a set or starting a workout—on the screen, giving the perception of instantaneous speed even if the server hasn't been reached yet.40  
* **Conflict Resolution**: If a user updates their routine on a desktop and then logs a workout on their phone while offline, the app must implement a "Last-Write-Wins" or "Custom Merge" policy to ensure no data is lost upon reconnection.18

### **Wearable Integration and Biological Feedback**

In 2025, wearable technology is the number one global fitness trend.43 Integrating with smartwatches (Apple Watch, Wear OS) and health ecosystems (Apple HealthKit, Google Fit) transforms the app from a logbook into a comprehensive health coach.10

* **Biometric Data Ingestion**: The app should pull data on Heart Rate Variability (HRV), resting heart rate, and sleep quality.10  
* **Readiness Scoring**: High HRV and good sleep quality trigger suggestions to "push harder" and increase intensity. Conversely, markers of overtraining or poor recovery should trigger a "Deload" suggestion—automatically reducing the volume or intensity of the day’s routine to prevent injury.10  
* **Real-time Heart Rate Zoning**: During rest periods, the app can monitor the user's heart rate recovery to suggest exactly when to start the next set for optimal metabolic stress.10

## **Features Designed to Attract Paid Users (Monetization Strategy)**

The transition from a free user to a paid subscriber is driven by the desire for "Elite" status, deep analysis, and automated coaching that a basic logbook cannot provide.20

### **Monetization Models Overview**

| Model | Application | Benefit |
| :---- | :---- | :---- |
| **Freemium** | Core logging is free; advanced features are paid.47 | Low barrier to entry; high user acquisition.30 |
| **Subscription** | Monthly or annual fee for the "Pro" experience.30 | Sustainable, recurring revenue for continuous development.30 |
| **In-App Purchases** | Selling specialized training programs or meal plans.30 | One-time revenue from content-hungry users.45 |
| **Corporate Wellness** | Licensing the app to companies for employee health.30 | Scalable enterprise growth.45 |

### **High-Value "Pro" Features**

To justify a premium price point, the application must offer tangible benefits that improve the user's fitness outcomes or significantly save them time.9

#### **Advanced Progress Analytics**

While free users see a history of their lifts, Pro users receive a diagnostic view of their progress.5

* **Muscle Volume Heatmaps**: A visual representation of the body showing which muscle groups are reaching optimal volume targets and which are being neglected.10  
* **Estimated 1RM Trends**: Longitudinal charts showing how the user's theoretical strength is increasing over time, even if they never attempt a maximal lift.5  
* **Consistency Insights**: Advanced metrics on "Training Frequency" and "Workout Density" (work performed per minute).13

#### **Intelligent Auto-Regulation and Coaching**

This is the "Personal Trainer in your pocket" experience.13

* **Smart Load Suggestions**: Based on the previous set's RPE, the app tells the user exactly how much weight to add or remove for the next set to stay in the "Optimal Growth Zone".27  
* **Automated Plate Math**: Premium users get the interactive visual plate calculator, which supports micro-plates (0.25kg, 0.125kg) for advanced strength training.5  
* **Form Analysis with AI**: Using the camera to track bar speed and depth, providing real-time audio cues like "Slow down the descent" or "Squat deeper".10

#### **Community and Motivational Gamification**

Social status and competition are powerful drivers of retention.20

* **Verified Pro Leaderboards**: Private leaderboards where subscribers can compare their "Strength Score" against others in their weight class.20  
* **Premium Challenges**: Access to exclusive, time-bound challenges (e.g., "The 100-Mile Month") with digital "Elite" badges and potential physical rewards.20  
* **Social Training**: The ability to "Sync" a workout session with a friend in real-time, allowing two users to see each other's logged sets as they happen for mutual motivation.5

## **Security, Privacy, and Non-Functional Requirements**

As a fitness application collects increasingly sensitive biological data—including biometric identifiers, body measurements, and even location data for outdoor activities—security and privacy become paramount.23

### **Data Protection Standards**

* **Encryption**: All sensitive user information, specifically progress photos and body weight logs, must be encrypted both "at rest" (on the device) and "in transit" (during sync).18  
* **Compliance**: Adherence to data protection regulations such as GDPR (Europe) and CCPA (California) is mandatory.23 If the app integrates with medical providers, HIPAA compliance must be evaluated.23  
* **Anonymous Mode**: Allowing users to utilize the tracking features without a full account (local-only storage) appeals to privacy-conscious users.5

### **Reliability and System Health**

Fitness tracking is a mission-critical task for some athletes. A crash during a personal record (PR) attempt can lead to immediate uninstallation.40

* **Fault Tolerance**: The app should be designed to handle sudden restarts without losing the current "Active Workout" state. The state should be saved to the local database after every set.18  
* **Battery Optimization**: Logging a 90-minute workout should not consume more than 5-10% of the device's battery, necessitating efficient background task management.29  
* **Cross-Platform Consistency**: Ensuring that the routine management and data visualization experience is identical across iOS and Android.29

## **Future Horizons: Generative AI and the Next Era of Coaching**

The trajectory of fitness technology in 2025 points toward a shift from "tracking" to "anticipating" user needs through Generative AI and advanced sensors.43

### **Generative AI and Conversational Interfaces**

Large Language Models (LLMs) enable a more natural interaction with training data.10

* **Voice-Activated Logging**: Instead of tapping a screen with sweaty fingers, a user can say "Log that as 100 kilos for 8 reps, RPE 8," and the AI correctly parses the entry.10  
* **Personalized Training Insight**: A user can ask the app, "Why is my bench press stalling?" The AI then analyzes 6 months of volume data, sleep patterns, and recovery markers to provide a synthesized answer: "Your volume has increased too quickly, leading to accumulated fatigue; try a deload week".10

### **Emerging Wearable Categories**

Beyond the smartwatch, new hardware will provide deeper insights into human performance.44

* **Smart Clothing**: Compression shirts with embedded sensors that track muscle fiber recruitment and electrical activity (EMG), allowing the app to show exactly which muscle group is doing the work.44  
* **Biometric Rings and Continuous Monitors**: Devices like smart rings provide 24/7 recovery data, while continuous glucose monitors (CGMs) could eventually allow the app to suggest the optimal timing for a pre-workout meal.44

## **Conclusion: Strategic Recommendations for Development**

The construction of a modern workout tracking application requires a dual focus on "Operational Excellence" and "Intelligent Value-Add." The operational aspect is addressed by the user's core request: a frictionless, hierarchical system for managing exercises and routines that works seamlessly in the gym.16 Success in this area is achieved through an offline-first, thumb-optimized architecture that treats every set log as a high-stakes data point.11

The intelligent value-add—and the path to a sustainable subscription model—is found in the application of data science to those logs. By automating the calculations for progressive overload, estimating 1RM through validated formulas, and integrating biological recovery signals from wearables, the app moves from being a digital logbook to a predictive coaching platform.10

### **Final Implementation Roadmap**

1. **MVP Phase**: Focus on the relational database integrity and the "Gym Mode" UX. Ensure the routine-to-exercise hierarchy is robust and the logging interface is optimized for one-handed use.14  
2. **Analytics Phase**: Implement the algorithmic layer, starting with 1RM estimations and RPE-based autoregulation. Launch the initial progress visualization dashboards.2  
3. **Monetization Phase**: Introduce the premium features, specifically wearable deep-sync, AI-powered load suggestions, and the interactive plate calculator.20  
4. **Ecosystem Phase**: Expand into community features, sharing capabilities, and eventually conversational AI interfaces that leverage the accumulated training data to provide bespoke coaching advice.10

By adhering to these principles, the proposed application will not only fulfill the immediate tracking needs of the lifter but will also foster the long-term biological adaptations that are the ultimate goal of all strength training.2

#### **Works cited**

1. Progressive overload: the ultimate guide \- GymAware, accessed February 26, 2026, [https://gymaware.com/progressive-overload-the-ultimate-guide/](https://gymaware.com/progressive-overload-the-ultimate-guide/)  
2. Progressive Overload Workout: The Complete Guide to Getting Stronger Safely \- Setgraph: Workout Tracker App, accessed February 26, 2026, [https://setgraph.app/ai-blog/progressive-overload-workout-guide](https://setgraph.app/ai-blog/progressive-overload-workout-guide)  
3. How to Build a Database Schema for a Fitness Tracking Application? \- Tutorials \- Back4app, accessed February 26, 2026, [https://www.back4app.com/tutorials/how-to-build-a-database-schema-for-a-fitness-tracking-application](https://www.back4app.com/tutorials/how-to-build-a-database-schema-for-a-fitness-tracking-application)  
4. Building a Modern Workout Tracker: A Full-Stack Journey | by Drake Damon | Medium, accessed February 26, 2026, [https://medium.com/@dddamon06/building-a-modern-workout-tracker-a-full-stack-journey-d9f404cd7b02](https://medium.com/@dddamon06/building-a-modern-workout-tracker-a-full-stack-journey-d9f404cd7b02)  
5. Best App to Log Workouts in 2024: 7 Top Trackers Compared ..., accessed February 26, 2026, [https://setgraph.app/ai-blog/best-app-to-log-workouts](https://setgraph.app/ai-blog/best-app-to-log-workouts)  
6. Best Fitness Apps in 2025 – Top Picks by Category \- Gymscore, accessed February 26, 2026, [https://www.gymscore.ai/best-fitness-apps-2025](https://www.gymscore.ai/best-fitness-apps-2025)  
7. Top 10 Fitness Apps 2025: Free & Premium Apps Reviewed, accessed February 26, 2026, [https://dieringe.com/blog/fitness-apps](https://dieringe.com/blog/fitness-apps)

[image1]: <data:image/png;base64,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>

[image2]: <data:image/png;base64,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>
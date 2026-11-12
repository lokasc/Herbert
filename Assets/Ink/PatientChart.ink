// Chart unlocks: set to true when the player clicks that chart item.
// A topic only appears in "Ask Patient Questions" once its unlock is true
VAR medications_chart_question = false
VAR bloodpressure_chart_question = false
VAR heartrate_chart_question = false
VAR oxygen_chart_question = false
VAR history_chart_question = false
VAR age_chart_question = false
VAR bday_chart_question = false

// "Question asked" records. 
VAR medications_question_asked = false
VAR bloodpressure_question_asked = false
VAR heartrate_question_asked = false
VAR oxygen_question_asked = false
VAR history_question_asked = false
VAR age_question_asked = false

// Hidden information
VAR history_EF_question_discovered = false      // player earned the EF 30% note
VAR history_EF_halfquestion_discovered = false  // player used jargon, no EF number
VAR smoking_discovered = false
VAR firefighter_discovered = false

// Scores
VAR empathy = 0
VAR clarity = 0            // Not sure yet if we should be scoring this, check with Abhi
VAR hidden_found = 0       // +1 per hidden fact earned (guarded against repeats)
VAR mistake_points = 0     // Not sure yet if we should be scoring this, check with Abhi
VAR questions_asked = 0    // counts DIFFERENT topics (only increases on a topic's first visit)

// Different questions asked before the physical exam unlocks
CONST QUESTIONS_NEEDED = 5
// TAG LIST (for Esteban)

// ---- SCORING / CHARACTER TAGS ----
//   #empathyscore       On the "Current empathy: {empathy}" line. You don't need to print this but this is just in case you need to track where we've been printing the empathy score in ink.
//   #nursenotification  On every nurse line so you can find when the nurse line is being printed (set once, inside Nurse_Feedback).
//   #happy / #angry     Herbert's emotion on that line. For future art trigger reactions.
//   #empathy+1  On the first Herbert reaction line after a scored choice. Shows the empathy value of that choice. Easier for you guys to track empathy maybe?
//   #printasparagraph So we can mark which text needs to be printed as a whole
//
// ---- SYMPTOM TAGS ----
//   Each one sits on the FIRST line of the knot where that symptom's dialogue tree starts
//   #symptom_skips_water_pill 
//   #symptom_s3_gallop   
//   #symptom_bp_154_88   
//   #symptom_spo2_92   
//   #symptom_heart_history 
//   #topic_age  
//
// ---- CHART ITEM TAGS (on the first line of each chart screen) ----
//   Opening a chart item unlocks the matching question in "Ask Patient Questions".
//   #chart_name                 Full_Name
//   #chart_medications          Prescribed_Medications
//   #chart_age                  Age_Node
//   #chart_bp                   Blood_Pressure
//   #chart_auscultation         Auscultation_Node (S3 gallop note)
//   #chart_oxygen               Oxygen_Levels
//   #chart_visit_history        Visit_History
//   #chart_ef_note              The "Echo note on file: EF 30%" line. Only appears after the player earns it.
//
// ---- HIDDEN INFORMATION TAGS  ----
//   #hidden_info - Generic tag on every hidden-information discovery (catch all of them with this one)
//   #hidden_ef_30 
//   #hidden_heart_history_partial 
//   #hidden_smoking 
//   #hidden_firefighter 
//
// ---- OTHER LINE-TYPE TAGS ----
//   #repeat_question = Lines that ONLY appear when the player asks the same topic again (Herbert getting annoyed)
//   #system_message = Can appear as a notification maybe? Similar to the nursenotif?
//
// #empathy+int tags are labels of what the choice is worth. Empathy only counts on a topic's FIRST visit (see give_empathy), so on repeat visits the tag still appears but no points are added (at least in ink, and it shouldn't in unity). Read the {empathy} variable for the true score if you need to really make sure if its scoring right.
// The same applies to #hidden_info tags: the line can show again, but hidden_found only goes up once.


-> Patient_Introduction

// True once the player has asked enough different questions.
=== function can_proceed() === //esteban this isn't really necessary but I kept it locked on purpose so that in the ink, you technically can't skip to physical exam until you ask enough chart questions
//feel free to ignore this if you think its not needed
~ return questions_asked >= QUESTIONS_NEEDED
// Changes empathy ONLY when count_it is true. This is to prevent empathy farming
=== function give_empathy(amount, count_it) ===
{ count_it:
    ~ empathy = empathy + amount
}

// HOW REPEATS WORK: a knot's name inside a condition gives how many times it has been entered.
// { Medications_Convo > 1: ... } makes sure that the player does not gain empathy if this knot has been asked more than once.

=== Nurse_Feedback(line) ===
Nurse: {line} #nursenotification //this should help with triggering or catching when the nursenotification is played
+ [Continue] -> Scene1_Player_Decision

=== Patient_Introduction ===
Player: Herbert, yes? How are you? I heard you came in for a complaint regarding your breathing? 
Herbert: Yes, that's me. I know it's probably nothing, but I can't ignore it anymore.
Player: I'm sorry to hear that. Let me just take a look at your chart first and see what I can do.
Current empathy: {empathy} #empathyscore

+ [Begin examination]
    -> Scene1_Player_Decision

=== Scene1_Player_Decision ===
What would you like to do? 
Current empathy: {empathy} #empathyscore


+ [Look at Chart] -> Look_at_Chart
+ [Ask Patient Questions (Scene1)] -> Ask_Patient_Questions
+ { can_proceed() } [Proceed to Physical Exam (Scene2)] -> Patient_Physical


=== Look_at_Chart ===
Patient Chart 
Current empathy: {empathy} #empathyscore

+ [Full Name] -> Full_Name
+ [Prescribed Medications] -> Prescribed_Medications
+ [Age] -> Age_Node
+ [Blood Pressure] -> Blood_Pressure
+ [Auscultation Results] -> Auscultation_Node
+ [Oxygen Levels] -> Oxygen_Levels
+ [Medical Visit History] -> Visit_History
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Full_Name ===
Patient Information
Full Name: Herbert Bower
Current empathy: {empathy} #empathyscore 

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Prescribed_Medications ===
Herbert's chart lists the following medications: 
- Furosemide
- ASA 81 mg daily
- Spironolactone
- Colace Docusate 100 mg TID
~ medications_chart_question = true

You have reviewed Herbert's medication history. You can now ask him about his medications. #system_message
Current empathy: {empathy} #empathyscore

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Age_Node ===
Age: 71 
DOB: 3/1/1954
~ age_chart_question = true
~ bday_chart_question = true
You have reviewed Herbert's age. #system_message
And discovered his date of birth. #system_message
Current empathy: {empathy} #empathyscore

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Blood_Pressure ===
Herbert's Blood Pressure was taken right before coming here. 
Result: 154/88 mmHg
Current empathy: {empathy} #empathyscore
~ bloodpressure_chart_question = true

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Auscultation_Node ===
After listening to Herbert's heart with a stethoscope, the following was noted: 
S3 Gallop at apex
Current empathy: {empathy} #empathyscore
~ heartrate_chart_question = true

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Oxygen_Levels ===
According to previous checks, Herbert's current oxygen SpO2 levels are sitting at 92%.
Current empathy: {empathy} #empathyscore
~ oxygen_chart_question = true

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Visit_History ===
According to records, Herbert last visited the hospital one month ago. 
Current empathy: {empathy} #empathyscore
~ history_chart_question = true
{ history_EF_question_discovered:
    Echo note on file: EF 30% 
}

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Ask_Patient_Questions ===
Ask Herbert a question about his chart. 
Current empathy: {empathy} #empathyscore

+ { bloodpressure_chart_question } [Ask about his blood pressure] -> bloodpressure_Convo
+ { heartrate_chart_question } [Ask about his heart rate] -> heartrate_Convo
+ { oxygen_chart_question } [Ask about his oxygen] -> oxygen_Convo
+ { history_chart_question } [Ask about his medical history] -> History_Convo
+ { age_chart_question } [Ask about his age] -> Age_Convo
+ { medications_chart_question } [Ask about his medications] -> Medications_Convo
+ [Return to the Scene 1 menu] -> Scene1_Player_Decision

// MEDICATIONS

=== Medications_Convo ===
Player: I noticed on your chart you're taking some medications. #symptom_skips_water_pill
{ Medications_Convo > 1:
    Herbert: Not this question again...! #angry #repeat_question
}
Herbert: And if I am?
{ Medications_Convo == 1:
    ~ questions_asked = questions_asked + 1
}
~ medications_question_asked = true
Current empathy: {empathy} #empathyscore

+ [How often are you taking them?] Player: How often are you taking them?
    ~ give_empathy(1, Medications_Convo == 1)
    -> Meds_Convo_Response_1
+ [Do you take them regularly?] Player: Do you take them regularly?
    // empathy +0
    -> Meds_Convo_Response_2
+ [What medications did you stop taking?] Player: What medications did you stop taking?
    ~ give_empathy(-2, Medications_Convo == 1)
    -> Meds_Convo_Response_3


=== Meds_Convo_Response_1 ===
{ Medications_Convo > 1:
    Herbert: ...I already said! #angry #repeat_question
}
Herbert: ....four times a week? Maybe twice a week? I think? #empathy+1
Herbert: ...ok... fine, I admit it. I've been skipping them. Especially that damn water pill.
Herbert: It's too tiring having to get up every night just to use the bathroom.
Herbert admits that he hasn't been taking his medications consistently. 
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("GOOD JOB!")


=== Meds_Convo_Response_2 ===
{ Medications_Convo > 1:
    Herbert: ...Again? I already said... #angry #repeat_question
}
Herbert: Yes.
Herbert does not explain more. 
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Using yes or no questions may not always get you the detailed answers you need.")


=== Meds_Convo_Response_3 ===
Herbert: Are you accusing me of skipping my medicine? #angry #empathy-2
{ Medications_Convo > 1:
    Herbert: AGAIN!?  #angry #repeat_question
}
Herbert: I'm not careless! #angry
Herbert feels insulted.  
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Careful with how you phrase leading questions, especially if it might come off as rude.")

// MEDICAL HISTORY (with the hidden EF 30% branch)
=== History_Convo ===
Player: It says here on your chart that your last visit was a month ago. #symptom_heart_history
{ History_Convo > 1:
    Herbert: Not this question again... #angry #repeat_question
}
Herbert: I had a different issue back then and it was for nothing important, really.
{ History_Convo == 1:
    ~ questions_asked = questions_asked + 1
}
~ history_question_asked = true
Current empathy: {empathy} #empathyscore

+ [If you say so.] Player: If you say so.
    // empathy +0
    -> history_Convo_Response_1
+ [Please, I'd like to hear more about it.] Player: Please, I'd like to hear more about it.
    ~ give_empathy(2, History_Convo == 1)
    -> history_Convo_Response_2
+ [You must come here a lot.] Player: You must come here a lot.
    ~ give_empathy(-2, History_Convo == 1)
    -> history_Convo_Response_3

=== history_Convo_Response_1 ===
Herbert doesn't say more on the matter. 
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Try to dig deeper and use open-ended questions when communicating with patients.")

=== history_Convo_Response_2 === 
{ History_Convo > 1:
    Herbert: Like I said... #angry #repeat_question
}
Herbert: It wasn't for anything major. But I was told I had to get my heart checked. #empathy+2
Current empathy: {empathy} #empathyscore

+ [Did they check for the volumetric fraction of blood during ejection?] Player: Did they check for the volumetric fraction of blood during ejection?
    -> history_hidden_Response_1
+ [That sounds important. Do you remember anything your doctor might have said?] Player: That sounds important. Do you remember anything your doctor might have said?
    ~ give_empathy(2, History_Convo == 1)
    -> history_hidden_Response_2

// Jargon 
=== history_hidden_Response_1 ===
Herbert looks unsure but nods. 
Herbert: I guess.
You discover that Herbert has standing medical history for his heart. #system_message #hidden_info #hidden_heart_history_partial
Current empathy: {empathy} #empathyscore
~ history_EF_halfquestion_discovered = true

+ [Continue] -> Nurse_Feedback("Try to use familiar language and terminology when speaking with patients.")


// Plain-language 
=== history_hidden_Response_2 ===
Herbert: Not really, but maybe it's on my chart. #empathy+2
After double checking the chart, you realize that there is a note of EF 30%. #system_message #hidden_info #hidden_ef_30
{ not history_EF_question_discovered:
    ~ hidden_found = hidden_found + 1
}
~ history_EF_question_discovered = true
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("GOOD JOB!")


=== history_Convo_Response_3 ===
Herbert frowns. #empathy-2 
Herbert: Not out of choice. #angry
Herbert: No one likes being sick. 
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Avoid making comments that could be interpreted as judgemental or condescending.")


=== oxygen_Convo ===
Player: On your chart, I can see they already tested your oxygen levels. #symptom_spo2_92
{ oxygen_Convo > 1:
    Herbert: This again? #angry #repeat_question
}
Herbert: Are my numbers bad or something?
{ oxygen_Convo == 1:
    ~ questions_asked = questions_asked + 1
}
~ oxygen_question_asked = true
Current empathy: {empathy} #empathyscore
+ [Yes. Your oxygen levels are lower than normal.] Player: Yes. Your oxygen levels are lower than normal.
    ~ give_empathy(-1, oxygen_Convo == 1)
    -> oxygen_Convo_Response_1
+ [Your oxygen levels are perfectly fine for someone of your age.] Player: Your oxygen levels are perfectly fine for someone of your age.
    ~ give_empathy(-1, oxygen_Convo == 1)
    -> oxygen_Convo_Response_2
+ [I know you're worried, so let me first explain things further.] Player: I know you're worried, so let me first explain things further.
    ~ give_empathy(2, oxygen_Convo == 1)
    -> oxygen_Convo_Response_3


=== oxygen_Convo_Response_1 ===
Herbert looks panicked. #empathy-1 
Herbert: Oh god. This is exactly what the internet told me.
Herbert:...I'm dying, aren't I?
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Try not to label any details or prognosis as 'bad', for this can panic your patients.")


=== oxygen_Convo_Response_2 ===
Herbert: That still doesn't make sense. #empathy-1
Herbert: Why am I having a hard time breathing then?
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Please do not lie to your patients, even if you are trying to make them feel better.")


=== oxygen_Convo_Response_3 ===
Player: Multiple factors can play into this. #empathy+2
Player: So before we make any assumptions, do you mind me asking more questions?
Current empathy: {empathy} #empathyscore
"GOOD JOB!" #nursenotification
+ [Continue] -> oxygen_hidden_response_0


// Empathy and hidden-info points are guarded in the knots below
=== oxygen_hidden_response_0 ===
Ask Herbert a follow-up question. 
Current empathy: {empathy} #empathyscore

+ [Do you smoke or have a history of smoking?] Player: Do you smoke or have a history of smoking?
    -> oxygen_hidden_Smoking
+ [At any point, have you been exposed to a lot of smoke?] Player: At any point, have you been exposed to a lot of smoke?
    -> oxygen_hidden_Firefighter
+ [I think we can move on.] Player: I think we can move on.
    -> Scene1_Player_Decision


=== oxygen_hidden_Smoking ===
Herbert: To be honest, I used to smoke a lot, but I try not to now.
You discover Herbert's previous smoking habits. #system_message #hidden_info #hidden_smoking
You may want to note this for later. #system_message
{ not smoking_discovered:
    ~ hidden_found = hidden_found + 1
}
~ smoking_discovered = true
Current empathy: {empathy} #empathyscore

+ [Continue] -> oxygen_hidden_response_0


=== oxygen_hidden_Firefighter ===
Herbert: I did, actually. I used to work as a firefighter. #empathy+2
You discover Herbert's previous occupation. #system_message #hidden_info #hidden_firefighter
You may want to note this for later. #system_message
{ oxygen_hidden_Firefighter == 1:
    ~ empathy = empathy + 2
}
{ not firefighter_discovered:
    ~ hidden_found = hidden_found + 1
}
~ firefighter_discovered = true
Current empathy: {empathy} #empathyscore

+ [Continue] -> oxygen_hidden_response_0

=== Age_Convo ===
Player: Just to review, let's go over some basic information on your chart. #topic_age
{ Age_Convo == 1:
    ~ questions_asked = questions_asked + 1
}
~ age_question_asked = true

+ [Can you please confirm your birthday and age for me?] Player: Can you please confirm your birthday and age for me?
    -> Age_Convo_Response_1
+ [How old are you?] Player: How old are you?
    ~ give_empathy(-1, Age_Convo == 1)
    -> Age_Convo_Response_2


=== Age_Convo_Response_1 ===
Herbert: 71 years old.
Herbert: And I was born March 1, 1954.
Player: Looks good.
Player: Moving on...
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("GOOD JOB!")



=== Age_Convo_Response_2 ===
Herbert: Older than you, that's for sure. #angry #empathy-1
Herbert: Why are you asking me this? #angry
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Be clear and professional when asking questions.")

=== heartrate_Convo ===
Player: I saw on your chart that someone was able to take down your heart rate. #symptom_s3_gallop
Player: And I see here that they noted a S3 Gallop at Apex.
{ heartrate_Convo > 1:
    Herbert: Are you seriously asking this again? #angry #repeat_question
    Player: Yes...? #repeat_question
- else:
    Herbert: Excuse me?
}
{ heartrate_Convo == 1:
    ~ questions_asked = questions_asked + 1
}
~ heartrate_question_asked = true
Current empathy: {empathy} #empathyscore

+ [It just means that there was an extra heart sound indicating ventricular overload] Player: It just means that there was an extra heart sound indicating ventricular overload.
    ~ give_empathy(-2, heartrate_Convo == 1)
    -> heartrate_Convo_Response_1
+ [Let's just say it's a good thing you came here to get help.] Player: Let's just say it's a good thing you came here to get help.
    ~ give_empathy(-1, heartrate_Convo == 1)
    -> heartrate_Convo_Response_2
+ [Your heart is working harder than what might be considered normal.] Player: Your heart is working harder than what might be considered normal.
    ~ give_empathy(3, heartrate_Convo == 1)
    -> heartrate_Convo_Response_3


=== heartrate_Convo_Response_1 ===
Herbert: Whatever you say. #empathy-2
Herbert looks absolutely confused, but doesn't say more. 
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Try to use familiar language and terminology when speaking with patients.")


=== heartrate_Convo_Response_2 ===
Herbert: Whatever. #angry #empathy-1
Herbert looks annoyed but doesn't say more. #angry 
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Avoiding an explanation can come off as rude.")


=== heartrate_Convo_Response_3 ===
Herbert: Is that what it means? That's good to know. #happy #empathy+3
Player: It is. You don't need to memorize the numbers or the terms, but it's always good to be self-aware of your condition.
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("GOOD JOB!")


=== bloodpressure_Convo ===
Player: Looking at your chart, I noticed your blood pressure was taken. #symptom_bp_154_88
{ bloodpressure_Convo > 1:
    Herbert: Again with the blood pressure? #angry #repeat_question
}
Herbert: Yes it was. What's the verdict?
{ bloodpressure_Convo == 1:
    ~ questions_asked = questions_asked + 1
}
~ bloodpressure_question_asked = true
Current empathy: {empathy} #empathyscore

+ [Based on what I'm seeing, your blood pressure is a slightly higher than usual.] Player: Based on what I'm seeing, your blood pressure is a slightly higher than usual.
    ~ give_empathy(2, bloodpressure_Convo == 1)
    -> bloodpressure_Convo_Response_1
+ [It says here that you have a BP of 154/88 mmHg.] Player: It says here that you have a BP of 154/88 mmHg.
    ~ give_empathy(-1, bloodpressure_Convo == 1)
    -> bloodpressure_Convo_Response_2
+ [I think we need to focus on hitting a goal of 130/80 mmHg.] Player: I think we need to focus on hitting a goal of 130/80 mmHg.
    ~ give_empathy(-1, bloodpressure_Convo == 1)
    -> bloodpressure_Convo_Response_3


=== bloodpressure_Convo_Response_1 ===
Herbert: I think I understand now...should I be worried if it is that high? #empathy+2
Player: That ultimately depends on your final assessment. Let's continue this going over your medical details first.
Herbert: Sounds like a plan. #happy
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("GOOD JOB!")


=== bloodpressure_Convo_Response_2 ===
Herbert: ...I guess that's...interesting? #empathy-1
Player: Not to worry. We'll first cross-check it with the rest of your medical details before coming to any conclusions.
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Try to use familiar language and terminology when speaking with patients.")


=== bloodpressure_Convo_Response_3 ===
Herbert: Okay...whatever you say...? #empathy-1
Player: Moving on!
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Try to use familiar language and terminology when speaking with patients.")

=== Patient_Physical ===
CURRENTLY IN PROGRESS... 
-> END
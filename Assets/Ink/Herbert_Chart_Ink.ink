
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


-> Patient_Introduction


// FUNCTIONS 
// True once the player has asked enough different questions.
=== function can_proceed() ===
~ return questions_asked >= QUESTIONS_NEEDED
// Changes empathy ONLY when count_it is true. This is to prevent empathy farming.
=== function give_empathy(amount, count_it) ===
{ count_it:
    ~ empathy = empathy + amount
}

// HOW REPEATS WORK: a knot's name inside a condition gives how many times it has been entered.
// { Medications_Convo > 1: ... } makes sure that the player does not gain empathy if this knot has been asked more than once.

=== Nurse_Feedback(line) ===
Nurse: {line}

+ [Continue] -> Scene1_Player_Decision

=== Patient_Introduction ===
Player: Herbert, yes? How are you? I heard you came in for a complaint regarding your breathing?
Herbert: Yes, that's me. I know it's probably nothing, but I can't ignore it anymore.
Player: I'm sorry to hear that. Let me just take a look at your chart first and see what I can do.
Current empathy: {empathy}

+ [Begin examination]
    -> Scene1_Player_Decision

// SCENE 1 MENU

=== Scene1_Player_Decision ===
What would you like to do?
Current empathy: {empathy}

+ [Look at Chart] -> Look_at_Chart
+ [Ask Patient Questions (Scene1)] -> Ask_Patient_Questions
+ { can_proceed() } [Proceed to Physical Exam (Scene2)] -> Patient_Physical


=== Look_at_Chart ===
Patient Chart
Current empathy: {empathy}

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
Current empathy: {empathy}

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Prescribed_Medications ===
Herbert's chart lists the following medications:
- Furosemide
- ASA 81 mg daily
- Spironolactone
- Colace Docusate 100 mg TID
~ medications_chart_question = true

You have reviewed Herbert's medication history. You can now ask him about his medications.
Current empathy: {empathy}

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Age_Node ===
Age: 71
DOB: 3/1/1954
~ age_chart_question = true
~ bday_chart_question = true
You have reviewed Herbert's age.
And discovered his date of birth.
Current empathy: {empathy}

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Blood_Pressure ===
Herbert's Blood Pressure was taken right before coming here.
Result: 154/88 mmHg
Current empathy: {empathy}
~ bloodpressure_chart_question = true

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Auscultation_Node ===
After listening to Herbert's heart with a stethoscope, the following was noted:
S3 Gallop at apex
Current empathy: {empathy}
~ heartrate_chart_question = true

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Oxygen_Levels ===
According to previous checks, Herbert's current oxygen SpO2 levels are sitting at 92%.
Current empathy: {empathy}
~ oxygen_chart_question = true

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Visit_History ===
According to records, Herbert last visited the hospital one month ago.
Current empathy: {empathy}
~ history_chart_question = true
{ history_EF_question_discovered:
    Echo note on file: EF 30%
}

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Ask_Patient_Questions ===
Ask Herbert a question about his chart.
Current empathy: {empathy}

+ { bloodpressure_chart_question } [Ask about his blood pressure] -> bloodpressure_Convo
+ { heartrate_chart_question } [Ask about his heart rate] -> heartrate_Convo
+ { oxygen_chart_question } [Ask about his oxygen] -> oxygen_Convo
+ { history_chart_question } [Ask about his medical history] -> History_Convo
+ { age_chart_question } [Ask about his age] -> Age_Convo
+ { medications_chart_question } [Ask about his medications] -> Medications_Convo
+ [Return to the Scene 1 menu] -> Scene1_Player_Decision


// =====================================================================
// MEDICATIONS
// =====================================================================
=== Medications_Convo ===
Player: I noticed on your chart you're taking some medications.
{ Medications_Convo > 1:
    Herbert: Not this question again...!
}
Herbert: And if I am?
{ Medications_Convo == 1:
    ~ questions_asked = questions_asked + 1
}
~ medications_question_asked = true
Current empathy: {empathy}

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
    Herbert: ...I already said!
}
Herbert: ....four times a week? Maybe twice a week? I think?
Herbert: ...ok... fine, I admit it. I've been skipping them. Especially that damn water pill.
Herbert: It's too tiring having to get up every night just to use the bathroom.
Herbert admits that he hasn't been taking his medications consistently.
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("GOOD JOB!")


=== Meds_Convo_Response_2 ===
{ Medications_Convo > 1:
    Herbert: ...Again? I already said...
}
Herbert: Yes.
Herbert does not explain more.
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("Using yes or no questions may not always get you the detailed answers you need.")


=== Meds_Convo_Response_3 ===
Herbert: Are you accusing me of skipping my medicine?
{ Medications_Convo > 1:
    Herbert: AGAIN!?
}
Herbert: I'm not careless!
Herbert feels insulted.
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("Careful with how you phrase leading questions, especially if it might come off as rude.")


// =====================================================================
// MEDICAL HISTORY (with the hidden EF 30% branch)
// =====================================================================
=== History_Convo ===
Player: It says here on your chart that your last visit was a month ago.
{ History_Convo > 1:
    Herbert: Not this question again...
}
Herbert: I had a different issue back then and it was for nothing important, really.
{ History_Convo == 1:
    ~ questions_asked = questions_asked + 1
}
~ history_question_asked = true
Current empathy: {empathy}

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
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("Try to dig deeper and use open-ended questions when communicating with patients.")


=== history_Convo_Response_2 ===
{ History_Convo > 1:
    Herbert: Like I said...
}
Herbert: It wasn't for anything major. But I was told I had to get my heart checked.
Current empathy: {empathy}

+ [Did they check for the volumetric fraction of blood during ejection?] Player: Did they check for the volumetric fraction of blood during ejection?
    -> history_hidden_Response_1
+ [That sounds important. Do you remember anything your doctor might have said?] Player: That sounds important. Do you remember anything your doctor might have said?
    ~ give_empathy(2, History_Convo == 1)
    -> history_hidden_Response_2


// Jargon 
=== history_hidden_Response_1 ===
Herbert looks unsure but nods.
Herbert: I guess.
You discover that Herbert has standing medical history for his heart.
Current empathy: {empathy}
~ history_EF_halfquestion_discovered = true

+ [Continue] -> Nurse_Feedback("Try to use familiar language and terminology when speaking with patients.")


// Plain-language 
=== history_hidden_Response_2 ===
Herbert: Not really, but maybe it's on my chart.
After double checking the chart, you realize that there is a note of EF 30%.
{ not history_EF_question_discovered:
    ~ hidden_found = hidden_found + 1
}
~ history_EF_question_discovered = true
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("GOOD JOB!")


=== history_Convo_Response_3 ===
Herbert frowns.
Herbert: Not out of choice.
Herbert: No one likes being sick.
Current empathy: {empathy}

+ [Continue] -> Scene1_Player_Decision


=== oxygen_Convo ===
Player: On your chart, I can see they already tested your oxygen levels.
{ oxygen_Convo > 1:
    Herbert: This again?
}
Herbert: Are my numbers bad or something?
{ oxygen_Convo < 1:
    ~ questions_asked = questions_asked + 1
}
~ oxygen_question_asked = true
Current empathy: {empathy}
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
Herbert looks panicked.
Herbert: Oh god. This is exactly what the internet told me.
Herbert:...I'm dying, aren't I?
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("Try not to label any details or prognosis as 'bad', for this can panic your patients.")


=== oxygen_Convo_Response_2 ===
Herbert: That still doesn't make sense.
Herbert: Why am I having a hard time breathing then?
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("Please do not lie to your patients, even if you are trying to make them feel better.")


=== oxygen_Convo_Response_3 ===
Player: Multiple factors can play into this.
Player: So before we make any assumptions, do you mind me asking more questions?
Current empathy: {empathy}

+ [Continue] -> oxygen_hidden_response_0


// Empathy and hidden-info points are guarded in the knots below.
=== oxygen_hidden_response_0 ===
Ask Herbert a follow-up question.
Current empathy: {empathy}

+ [Do you smoke or have a history of smoking?] Player: Do you smoke or have a history of smoking?
    -> oxygen_hidden_Smoking
+ [At any point, have you been exposed to a lot of smoke?] Player: At any point, have you been exposed to a lot of smoke?
    -> oxygen_hidden_Firefighter
+ [I think we can move on.] Player: I think we can move on.
    -> Scene1_Player_Decision


=== oxygen_hidden_Smoking ===
Herbert: To be honest, I used to smoke a lot, but I try not to now.
You discover Herbert's previous smoking habits.
You may want to note this for later.
{ not smoking_discovered:
    ~ hidden_found = hidden_found + 1
}
~ smoking_discovered = true
Current empathy: {empathy}

+ [Continue] -> oxygen_hidden_response_0


=== oxygen_hidden_Firefighter ===
Herbert: I did, actually. I used to work as a firefighter.
You discover Herbert's previous occupation.
You may want to note this for later.
{ oxygen_hidden_Firefighter == 1:
    ~ empathy = empathy + 2
}
{ not firefighter_discovered:
    ~ hidden_found = hidden_found + 1
}
~ firefighter_discovered = true
Current empathy: {empathy}

+ [Continue] -> oxygen_hidden_response_0

=== Age_Convo ===
Player: Just to review, let's go over some basic information on your chart.
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
Current empathy: {empathy}

+ [Continue] -> Scene1_Player_Decision


=== Age_Convo_Response_2 ===
Herbert: Older than you, that's for sure.
Herbert: Why are you asking me this?
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("Be clear and professional when asking questions.")

=== heartrate_Convo ===
Player: I saw on your chart that someone was able to take down your heart rate.
Player: And I see here that they noted a S3 Gallop at Apex.
{ heartrate_Convo > 1:
    Herbert: Are you seriously asking this again?
    Player: Yes.
- else:
    Herbert: Excuse me?
}
{ heartrate_Convo == 1:
    ~ questions_asked = questions_asked + 1
}
~ heartrate_question_asked = true
Current empathy: {empathy}

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
Herbert: Whatever you say.
Herbert looks absolutely confused, but doesn't say more.
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("Try to use familiar language and terminology when speaking with patients.")


=== heartrate_Convo_Response_2 ===
Herbert: Whatever.
Herbert looks annoyed but doesn't say more.
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("Avoiding an explanation can come off as rude.")


=== heartrate_Convo_Response_3 ===
Herbert: Is that what it means? That's good to know.
Player: It is. You don't need to memorize the numbers or the terms, but it's always good to be self-aware of your condition.
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("GOOD JOB!")


=== bloodpressure_Convo ===
Player: Looking at your chart, I noticed your blood pressure was taken.
{ bloodpressure_Convo > 1:
    Herbert: Again with the blood pressure?
}
Herbert: Yes it was. What's the verdict?
{ bloodpressure_Convo == 1:
    ~ questions_asked = questions_asked + 1
}
~ bloodpressure_question_asked = true
Current empathy: {empathy}

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
Herbert: I think I understand now...should I be worried if it is that high?
Player: That ultimately depends on your final assessment. Let's continue this going over your medical details first.
Herbert: Sounds like a plan.
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("GOOD JOB!")


=== bloodpressure_Convo_Response_2 ===
Herbert: ...I guess that's...interesting?
Player: Not to worry. We'll first cross-check it with the rest of your medical details before coming to any conclusions.
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("Try to use familiar language and terminology when speaking with patients.")


=== bloodpressure_Convo_Response_3 ===
Herbert: Okay...whatever you say...?
Player: Moving on!
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("Try to use familiar language and terminology when speaking with patients.")

=== Patient_Physical ===
CURRENTLY IN PROGRESS...
-> END
VAR water_asked = false
// "Question asked" records. Use this to track for MCQ
VAR wife_topics_question = false
VAR main_complaint_topics_question = false
VAR other_complaint_topics_question = false
VAR drinking_topics_question = false

// "Question asked" records. Use this to track for MCQ
VAR medications_question_asked = false
VAR bloodpressure_question_asked = false
VAR heartrate_question_asked = false
VAR oxygen_question_asked = false
VAR history_question_asked = false
VAR age_question_asked = false

VAR medications_chart_question = false
VAR bloodpressure_chart_question = false
VAR heartrate_chart_question = false
VAR oxygen_chart_question = false
VAR history_chart_question = false
VAR age_chart_question = false

// Hidden information
VAR history_EF_question_discovered = false      // player earned the EF 30% note (the chart reads this)

// Scores
VAR empathy = 0

// SCORING (best case = +5)
//   Medications   "How often are you taking them?"                      +1
//   History       "Please, I'd like to hear more about it."             +1
//   History 2nd   skill gate, no empathy                                 0
//   Oxygen        "I know you're worried, so let me first explain..."   +1
//   Oxygen 2nd    skill gate, no empathy                                 0
//   Blood press.  "...slightly higher than usual."                      +1
//   Age           "Can you please confirm your birthday and age..."      0
//   Heart (exam)  "Your heart is working harder than...normal."         +1
// Wrong options at these points stay at -1 (Age: -1 on "How old are you?").
// Main complaint, Diet, Wife and Drinking branches no longer change empathy.

//tag list for esteban
//   HERBERT: / PLAYER: / NURSE:   prefix on EVERY spoken line = who is talking. Strip the prefix before display (use it for name label / portrait). The spoken text is wrapped in " " so it still reads as speech after stripping.
//   Choice buttons that are things the player says are also wrapped in " ". Navigation buttons (Continue, Return, Look at Chart...) are not.
//   #nursenotification  on every nurse line so you can find when the nurse line is being printed (set once, inside Nurse_Feedback).
//   #happy / #angry     Herbert's emotion on that line. For future art trigger reactions.
//   #printasparagraph so we can mark which text needs to be printed as a whole
//   #repeat_question = lines that ONLY appear when the player asks the same topic again (Herbert getting annoyed)
//   #system_message = Can appear as a notification
// Lines WITHOUT a HERBERT:/PLAYER:/NURSE: prefix are narration / chart text / system messages.

// #checkchartagain = the one line that is dependent on whether all chart variables are true/completed 


-> Patient_Introduction
// Changes empathy ONLY when count_it is true. This is to prevent empathy farming
=== function give_empathy(amount, count_it) ===
{ count_it:
    ~ empathy = empathy + amount
}
// HOW REPEATS WORK: a knot's name inside a condition gives how many times it has been entered.
// { Medications_Convo > 1: ... } makes sure that the player does not gain empathy if this knot has been asked more than once.

=== Nurse_Feedback(line) ===
"{line}" #nursenotification //this should help with triggering or catching when the nursenotification is played
+ [Continue] -> Scene1_Player_Decision

=== Patient_Introduction ===
PLAYER: "Herbert, yes? How are you? I heard you came in for a complaint regarding your breathing?"
HERBERT: "Yes, that's me. I know it's probably nothing, but it's been bothering me a lot."
PLAYER: "Oh, I'm sorry to hear that."
PLAYER: "Let me just take a look at your chart first and see what I can do."
Current empathy: {empathy} #empathyscore

+ [Begin examination]
    -> Scene1_Player_Decision

=== Scene1_Player_Decision ===
What would you like to do? 
Current empathy: {empathy} #empathyscore

+ [Look at Chart] -> Look_at_Chart
+ [Ask Patient Questions (Scene1)] -> Ask_Patient_Questions
+ [Proceed to Physical Exam (Scene2)] -> Patient_Physical

//ALL CHART CLICKABLES
=== Look_at_Chart ===
On the chart, you see the following: 
Current empathy: {empathy} #empathyscore

+ [Full Name] -> Full_Name
+ [Prescribed Medications] -> Prescribed_Medications
+ [Age] -> Age_Node
+ [Blood Pressure] -> Blood_Pressure
+ [Auscultation Results] -> Auscultation_Node //to be removed IF PHYSICAL CAN ACCOUNT FOR THIS
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
Herbert's chart lists the following medications: //#printasparagraph
- Furosemide (a diuretic, also called a “water pill”) #printasparagraph
- ASA 81 mg daily#printasparagraph
- Spironolactone#printasparagraph
- Colace Docusate 100 mg TID#printasparagraph
~ medications_chart_question = true

You have reviewed Herbert's medication history.#system_message
You can now ask him about it later. #system_message
Current empathy: {empathy} #empathyscore

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Age_Node ===
Date of Birth: 3/3/1954
~ age_chart_question = true
You have reviewed Herbert's date of birth. #system_message
You can now ask him about it later. #system_message
Current empathy: {empathy} #empathyscore

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Blood_Pressure ===
BP Result: 154/88 mmHg
You have reviewed Herbert's blood pressure.#system_message
You can now ask him about it later. #system_message
Current empathy: {empathy} 
~ bloodpressure_chart_question = true

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision

=== Auscultation_Node ===
After listening to Herbert's heart with a stethoscope, the following was noted: 
S3 Gallop at apex
You have reviewed Herbert's heart rate.#system_message
You can now ask him about it later. #system_message
Current empathy: {empathy} 
~ heartrate_chart_question = true

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Oxygen_Levels ===
SpO2: 92%.
You have reviewed Herbert's heart rate.#system_message
You can now ask him about it later. #system_message
Current empathy: {empathy} 
~ oxygen_chart_question = true

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision

=== Visit_History ===
Last Hospital Visit: One month ago. 
You have reviewed Herbert's appointment history.#system_message
You can now ask him about it later. #system_message
Current empathy: {empathy} 
~ history_chart_question = true
{ history_EF_question_discovered:
    Echo note on file: EF 30% 
}

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision

//ALL TOPICS CLICKABLES MAIN HUB
=== Ask_Patient_Questions ===
Would you like to ask Herbert a question? 
Current empathy: {empathy} 

* [Ask about his main complaint] -> Main_Complaint
* [Ask about other symptoms] -> Other_Symptoms_Question
* [Ask about his diet] -> Diet_Question
* [Ask about his drinking habits] -> Drinking_Question

//TO ASK THE GROUP -- do we want questions to be repeatable or do we want them to diseappar? SOLVED!

* { bloodpressure_chart_question } [Ask about his blood pressure] -> bloodpressure_Convo
* { heartrate_chart_question } [Ask about his heart rate] -> heartrate_Convo
* { oxygen_chart_question } [Ask about his oxygen] -> oxygen_Convo
* { history_chart_question } [Ask about his medical history] -> History_Convo
* { age_chart_question } [Ask about his age] -> Age_Convo
* { medications_chart_question } [Ask about his medications] -> Medications_Convo

//esteban's button idea (kinda clunky how I had the check done but it works!
+ { not bloodpressure_chart_question or not heartrate_chart_question or not oxygen_chart_question or not history_chart_question or not age_chart_question or not medications_chart_question } [Review the chart for more information] #checkchartagain -> Look_at_Chart 
+ [Return to the Scene 1 menu] -> Scene1_Player_Decision

//ALL TOPICS CLICKABLE BRANCHES
=== Main_Complaint ===
PLAYER: "So, it says here you’ve been having trouble breathing."
~ main_complaint_topics_question = true
+ ["How would you rate your difficulty breathing on a scale of 1 to 10?"] 
    -> Main_Complaint_Response_1
+ ["Is there anything else you want to tell us?"] 
    ->  Main_Complaint_Response_2
+ ["I'm sure it's nothing to worry about. Can you breathe okay now?"] 
    -> Main_Complaint_Response_3

=== Main_Complaint_Response_1 ===
HERBERT: "On a scale of 1 to 10?"
HERBERT: "Well, I guess a 7 or 8."
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Great job! You got the information you needed!")

=== Main_Complaint_Response_2 ===
Herbert looks like he wants to say more...but doesn't.
HERBERT: "No. That’s right."
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("Ask open-ended questions instead of leading questions")

=== Main_Complaint_Response_3 ===
HERBERT: "Yeah, it’s not that bad. I’ve gotten pretty used to it at this point."
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Ask open-ended questions instead of leading questions")

=== Other_Symptoms_Question ===
PLAYER: "After taking a look at your chart..."
~other_complaint_topics_question =true
+ ["Are you feeling any other symptoms?"] 
-> Other_Symptoms_Question_Response_2
+ ["I'd like to know if there are any symptoms I may have missed."] 
-> Other_Symptoms_Question_Response_1
+ ["Are you feeling any cephalalgia, myalgia, arthralgia, nausea, emesis, dyspnea, or paresthesia?"] 
-> Other_Symptoms_Question_Response_3

=== Other_Symptoms_Question_Response_1 ===
HERBERT: "There’s something in my chest. I keep coughing."
Current empathy: {empathy} 
-> Other_Symptoms_Question_2

=== Other_Symptoms_Question_Response_2 ===
HERBERT: "Yeah. Mostly the breathing thing."
Current empathy: {empathy} 
+ [Continue] -> Nurse_Feedback("You won’t get as much info by asking yes or no questions")

=== Other_Symptoms_Question_Response_3 ===
Herbert nods.
He didn’t understand if you were asking for something from him.
Current empathy: {empathy} 
+ [Continue] -> Nurse_Feedback("Use familiar language instead of clinical terms")

=== Other_Symptoms_Question_2 ===
PLAYER: "That sounds concerning. If you don't mind me asking..."
+ ["When did that start?"] -> Other_Symptoms_Question_2_Response_1
+ {not water_asked}["Would you like some water?"]
    ~ water_asked = true
    -> Other_Symptoms_Question_2_Response_2
+ ["Where does it hurt?"] -> Other_Symptoms_Question_2_Response_3

=== Other_Symptoms_Question_2_Response_1 ===
HERBERT: "Well, about 4 days ago I think."
PLAYER: "Interesting. I'll note that down for later."
Current empathy: {empathy} 
+ [Continue] -> Ask_Patient_Questions

=== Other_Symptoms_Question_2_Response_3 ===
PLAYER: "Can you point to exactly where your chest hurts?"
Herbert points at his mid-sternal region.
PLAYER: "I see. Let me just write that down quickly."
Current empathy: {empathy} 
+ [Continue] -> Ask_Patient_Questions

=== Other_Symptoms_Question_2_Response_2 ===
HERBERT: "No, I’m okay, thanks."
PLAYER: "Just making sure. Let's move on."
Current empathy: {empathy} 
+ [Continue] -> Other_Symptoms_Question_2

=== Diet_Question ===
PLAYER: "I wanted to ask a little bit more about your diet..."
+ ["I think we need to talk about your weight."]
-> Diet_Question_Response_2
+ ["Do you think you'd consider your diet to be healthy?"] 
-> Diet_Question_Response_3
+ ["What do you typically eat?"] 
-> Diet_Question_Response_1

=== Diet_Question_Response_1 ===
{ Diet_Question > 1:
    HERBERT: "Like I already said..." #angry #repeat_question
}
HERBERT: "I mostly eat frozen dinners, chips, pizza."
HERBERT: "...not the best diet, I know."
Current empathy: {empathy} 
+ ["I hope you're taking care of yourself."] 
    -> Diet_Question_2_Response_1
+ ["Are you eating your fruits and vegetables?"]
    -> Diet_Question_2_Response_2

=== Diet_Question_Response_2 ===
HERBERT: "Are you calling me FAT!?" #angry
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Avoid sounding judgemental or condescending.")

=== Diet_Question_Response_3 ===
HERBERT: "Yeah. I guess."
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("You won’t get as much info by asking yes or no questions.")

=== Diet_Question_2_Response_1 ===
~wife_topics_question = true
HERBERT: "I'm...trying my best."
HERBERT: "My wife died a few months ago, and things sort of went downhill from there."
Current empathy: {empathy} 
-> Wife_Question

=== Diet_Question_2_Response_2 ===
HERBERT: "…I eat potatoes sometimes, if that counts."
HERBERT: "I'm sorry, what exactly is the point of this question?" #angry
Current empathy: {empathy} 
+ [Continue] -> Nurse_Feedback("Try to ask relevant questions to avoid confusing your patients.")

=== Wife_Question ===
Herbert looks like he wants to say more...
+ [(Let him keep talking)]
    -> Wife_Question_Response_1
+ ["Can we talk about something else?"]
    -> Wife_Question_Response_2

=== Wife_Question_Response_1 ===
HERBERT: "It makes no sense. She was never sick...in fact, she was always the one taking care of me. But the cancer was just so quick..."
Current empathy: {empathy} 
-> Wife_Question_2

=== Wife_Question_Response_2 ===
PLAYER: "Actually, let’s get back to the assessment."
HERBERT: "Yeah...I'm just rambling anyway."
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("Try to be a thoughtful listener with your patients...it might come in handy later.")

=== Wife_Question_2 ===
+ ["I'm sorry to hear that. I'm sure she's in a better place."]
    -> Wife_Question_2_Response_1
+ ["How has that impacted your daily life?"]
    -> Wife_Question_2_Response_2

=== Wife_Question_2_Response_1 ===
HERBERT: "Better place? Without me?"
HERBERT: "I didn't come here for therapy." #angry
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Try to be a thoughtful listener with your patients...it might come in handy later.")

=== Wife_Question_2_Response_2 ===
HERBERT: "I try to manage the best I can, but it's hard without her."
HERBERT: "She used to do all the cooking, you know."
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Great job considering Herbert’s feelings!")

=== Drinking_Question ===
PLAYER: "If you don't mind me asking..."
~ drinking_topics_question = true
+ ["Do you drink alcohol?"] -> Drinking_Question_Response_1
+ ["How much alcohol do you drink in a day?"] -> Drinking_Question_Response_2
+ ["What have you been drinking lately?"] -> Drinking_Question_Response_3

=== Drinking_Question_Response_1 ===
HERBERT: "Yeah, a little."
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("You won’t get as much info by asking yes or no questions.")

=== Drinking_Question_Response_2 ===
HERBERT: "I used to do just a couple beers, but lately it’s been more like 3 or 4…and a glass of wine."
Current empathy: {empathy} 

+ {not wife_topics_question} [Continue]-> Drinking_Question_2
+ {wife_topics_question}[Continue]-> Ask_Patient_Questions

=== Drinking_Question_2 ===
~ wife_topics_question = true
+ ["Why have you been drinking more recently?"]
    -> Drinking_Question_2_Response_1
+ ["Have you tried to cut back on that?"]
    -> Drinking_Question_2_Response_2

=== Drinking_Question_Response_3 ===
HERBERT: "Orange juice, coke, water."
HERBERT: "...this seems like a waste of time. Why are you asking me this?" #angry
Current empathy: {empathy} 
+ [Continue] -> Nurse_Feedback("Try to ask relevant questions to avoid confusing your patients.")

=== Drinking_Question_2_Response_1 ===
HERBERT: "My wife died three months ago, and things sort of went downhill from there."
Current empathy: {empathy} 

->Wife_Question

=== Drinking_Question_2_Response_2 ===
HERBERT: "Of course. It’s just hard." #angry
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Avoid sounding judgemental or condescending.")

///ALL OF THE CHART UNLOCKED CONVO STUFF
=== Medications_Convo ===
PLAYER: "I noticed on your chart you're taking some medications."
{ Medications_Convo > 1:
    HERBERT: "Not this question again...!" #angry #repeat_question
}
HERBERT: "And if I am?"
~ medications_question_asked = true
Current empathy: {empathy}

+ ["How often are you taking them?"] 
    ~ give_empathy(1, Medications_Convo == 1) 
    -> Meds_Convo_Response_1
+ ["Do you take them regularly?"] 
    -> Meds_Convo_Response_2
+ ["What medications did you stop taking?"] 
    ~ give_empathy(-1, Medications_Convo == 1)
    -> Meds_Convo_Response_3


=== Meds_Convo_Response_1 ===
{ Medications_Convo > 1:
    HERBERT: "...I already said!" #angry #repeat_question
}
HERBERT: "....four times a week? Maybe twice a week? I think?"
HERBERT: "...ok... fine, I admit it. I've been skipping them. Especially that damn water pill."
HERBERT: "It's too tiring having to get up every night just to use the bathroom."
Herbert admits that he hasn't been taking his medications consistently. 
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Great job! You got the information you needed!")


=== Meds_Convo_Response_2 ===
{ Medications_Convo > 1:
    HERBERT: "...Again? I already said..." #angry #repeat_question
}
HERBERT: "Yes."
Herbert does not explain more. 
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("You won’t get as much info by asking yes or no questions.")


=== Meds_Convo_Response_3 ===
HERBERT: "Are you accusing me of skipping my medicine?" #angry 
{ Medications_Convo > 1:
    HERBERT: "AGAIN!?" #angry #repeat_question
}
HERBERT: "I'm not careless!" #angry
Herbert feels insulted.  
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Don’t say something that could come off as rude.")

// MEDICAL HISTORY (with the hidden EF 30% branch)
=== History_Convo ===
PLAYER: "It says here on your chart that your last visit was a month ago."
{ History_Convo > 1:
    HERBERT: "Not this question again..." #angry #repeat_question
}
HERBERT: "I had a different issue back then and it was for nothing important, really."
~ history_question_asked = true
Current empathy: {empathy} 
+ ["If you say so."] 
    -> history_Convo_Response_1
+ ["Please, I'd like to hear more about it."] 
    ~ give_empathy(1, History_Convo == 1) 
    -> history_Convo_Response_2
+ ["You must come here a lot."] 
    ~ give_empathy(-1, History_Convo == 1)
    -> history_Convo_Response_3

=== history_Convo_Response_1 ===
Herbert doesn't say more on the matter. 
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Ask open-ended questions as much as possible.")

=== history_Convo_Response_2 === 
{ History_Convo > 1:
    HERBERT: "Like I said..." #angry #repeat_question
}
HERBERT: "It wasn't for anything major. But I was told I had to get my heart checked."
Current empathy: {empathy} 
PLAYER: "If you don't mind me asking..."
// History follow-up is a skill gate: no empathy change.
+ ["Did they check for the volumetric fraction of blood during ejection?"] 
    -> history_hidden_Response_1
+ ["That sounds important. Do you remember anything your doctor might have said?"] 
    -> history_hidden_Response_2


=== history_hidden_Response_1 ===
Herbert looks unsure but nods. 
HERBERT: "Maybe?"
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Try to use familiar language and terminology when speaking with patients.")

=== history_hidden_Response_2 ===
HERBERT: "Not really, but maybe it's on my chart."
After double checking the chart, you realize that there is a note of EF 30%. 
~ history_EF_question_discovered = true
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Great job! You got the information you needed!")


=== history_Convo_Response_3 ===
Herbert frowns. 
HERBERT: "Not out of choice." #angry
HERBERT: "No one likes being sick."
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Avoid making comments that could be interpreted as judgemental or condescending.")


=== oxygen_Convo ===
PLAYER: "On your chart, I can see they already tested your oxygen levels."

{ oxygen_Convo > 1:
    HERBERT: "This again?" #angry #repeat_question
}
HERBERT: "Are my numbers bad or something?"
~ oxygen_question_asked = true
Current empathy: {empathy} 
+ ["Yes. Your oxygen levels are lower than normal."] 
    ~ give_empathy(-1, oxygen_Convo == 1)
    -> oxygen_Convo_Response_1
+ ["Your oxygen levels are perfectly fine for someone of your age."] 
    ~ give_empathy(-1, oxygen_Convo == 1)
    -> oxygen_Convo_Response_2
+ ["I know you're worried, so let me first explain things further."] 
    ~ give_empathy(1, oxygen_Convo == 1)
    -> oxygen_Convo_Response_3


=== oxygen_Convo_Response_1 ===
Herbert looks panicked. 
HERBERT: "Oh god. This is exactly what the internet told me."
HERBERT: "...I'm dying, aren't I?"
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Try not to label any details or prognosis as 'bad', for this can panic your patients.")


=== oxygen_Convo_Response_2 ===
HERBERT: "That still doesn't make sense."
HERBERT: "Why am I having a hard time breathing then?"
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Careful. Giving innacurate information to your patients can lead to confusion.")

=== oxygen_Convo_Response_3 ===
PLAYER: "Multiple factors can play into this."
PLAYER: "So before we make any assumptions, do you mind me asking more questions?"
Current empathy: {empathy} 

+ [Continue] -> oxygen_hidden_response_0

=== oxygen_hidden_response_0 ===

PLAYER: "I wanted to ask..."
Current empathy: {empathy} 
// Oxygen follow-up is a skill gate: no empathy change.

+ ["It sounds like you smoke a lot."] 
    -> oxygen_hidden_Smoking
+ ["At any point, have you been exposed to a lot of smoke?"] 
    -> oxygen_hidden_Firefighter


=== oxygen_hidden_Smoking ===
HERBERT: "And so what if I do? Is it a crime to smoke now?" #angry
You discover Herbert's previous smoking habits. #system_message
You may want to note this for later. #system_message
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Avoid making comments that could be interpreted as judgemental or condescending.")


=== oxygen_hidden_Firefighter ===

HERBERT: "I did, actually. I used to work as a firefighter. And, to be honest, I used to smoke a lot too, but I try not to now."
You discover Herbert's previous occupation and smoking habits. #system_message
You may want to note this for later. #system_message
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Great job considering Herbert’s feelings!")

=== Age_Convo ===
PLAYER: "Just to review, let's go over some basic information on your chart."
{ Age_Convo > 1:
    HERBERT: "This again? I already told you." #angry #repeat_question 
    PLAYER: "Just humor me, please."
}
~ age_question_asked = true

+ ["Can you please confirm your birthday and age for me?"] 
    -> Age_Convo_Response_1
+ ["How old are you?"] 
    ~ give_empathy(-1, Age_Convo == 1)
    -> Age_Convo_Response_2


=== Age_Convo_Response_1 ===
HERBERT: "71 years old."
HERBERT: "And I was born March 3, 1954."
PLAYER: "Looks good."
PLAYER: "Moving on..."
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Great job staying professional!")

=== Age_Convo_Response_2 ===
HERBERT: "Older than you, that's for sure." #angry 
HERBERT: "Why are you asking me this?" #angry
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Be clear and professional when asking questions.")

=== heartrate_Convo ===
PLAYER: "I saw on your chart that someone was able to take down your heart rate."
PLAYER: "And I see here that they noted a S3 Gallop at Apex."

{ heartrate_Convo > 1:
    HERBERT: "Are you seriously asking this again?" #angry #repeat_question
    PLAYER: "Yes...?"
- else:
    HERBERT: "Excuse me?"
}
~ heartrate_question_asked = true
Current empathy: {empathy} 
PLAYER: "Seeing this..."
+ ["It just means that there was an extra heart sound indicating ventricular overload."] 
    ~ give_empathy(-1, heartrate_Convo == 1) 
    -> heartrate_Convo_Response_1
+ ["Let's just say it's a good thing you came here to get help."] 
    ~ give_empathy(-1, heartrate_Convo == 1)
    -> heartrate_Convo_Response_2
+ ["Your heart is working harder than what might be considered normal."] 
    ~ give_empathy(1, heartrate_Convo == 1) 
    -> heartrate_Convo_Response_3

=== heartrate_Convo_Response_1 ===
HERBERT: "Whatever you say."
Herbert looks absolutely confused, but doesn't say more. 
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Try to use familiar language and terminology when speaking with patients.")


=== heartrate_Convo_Response_2 ===
HERBERT: "Whatever." #angry 
Herbert looks annoyed but doesn't say more. #angry 
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Try not to say something that could come off as rude.")


=== heartrate_Convo_Response_3 ===
HERBERT: "Is that what it means? That's good to know." #happy 
PLAYER: "It is. You don't need to memorize the numbers or the terms, but it's always good to be self-aware of your condition."
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Great job! You’re communicating with your patient very well.")


=== bloodpressure_Convo ===
PLAYER: "Looking at your chart, I noticed your blood pressure was taken."
{ bloodpressure_Convo > 1:
    HERBERT: "Again with the blood pressure?" #angry #repeat_question
}
HERBERT: "Yes it was. What's the verdict?"
~ bloodpressure_question_asked = true
Current empathy: {empathy} 

+ ["Based on what I'm seeing, your blood pressure is a slightly higher than usual."]
    ~ give_empathy(1, bloodpressure_Convo == 1) 
    -> bloodpressure_Convo_Response_1
+ ["It says here that you have a BP of 154/88 mmHg."] 
    ~ give_empathy(-1, bloodpressure_Convo == 1)
    -> bloodpressure_Convo_Response_2
+ ["I think we need to focus on hitting a goal of 130/80 mmHg."] 
    ~ give_empathy(-1, bloodpressure_Convo == 1)
    -> bloodpressure_Convo_Response_3


=== bloodpressure_Convo_Response_1 ===
HERBERT: "I think I understand now...should I be worried if it is that high?"
PLAYER: "That ultimately depends on your final assessment. Let's go over the rest of your medical details first."
HERBERT: "Sounds like a plan." #happy
Current empathy: {empathy}

+ [Continue] -> Nurse_Feedback("Great job! You’re communicating with your patient very well.")


=== bloodpressure_Convo_Response_2 ===
HERBERT: "...I guess that's...interesting?"
PLAYER: "Not to worry. We'll first cross-check it with the rest of your medical details before coming to any conclusions."
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Try to use familiar language and terminology when speaking with patients.")


=== bloodpressure_Convo_Response_3 ===
HERBERT: "Okay...whatever you say...?"
PLAYER: "Moving on!"
Current empathy: {empathy} 

+ [Continue] -> Nurse_Feedback("Try to use familiar language and terminology when speaking with patients.")

=== Patient_Physical ===
CURRENTLY IN PROGRESS... 
-> END

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


// Switch between patient (chart), (interview), and nothing (base)
EXTERNAL switchState(stateName)


//tag list for esteban
//   #nursenotification  on every nurse line so you can find when the nurse line is being printed (set once, inside Nurse_Feedback).
//   #happy / #angry     Herbert's emotion on that line. For future art trigger reactions.
//   #printasparagraph so we can mark which text needs to be printed as a whole
//   #repeat_question = lines that ONLY appear when the player asks the same topic again (Herbert getting annoyed)
//   #system_message = Can appear as a notification 

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
{switchState("base")}
What would you like to do? 
Current empathy: {empathy} #empathyscore

+ [Look at Chart] -> Look_at_Chart
+ [Ask Patient Questions (Scene1)] -> Ask_Patient_Questions
+ [Proceed to Physical Exam (Scene2)] -> Patient_Physical


//ALL CHART CLICKABLES
=== Look_at_Chart ===
{switchState("chart")}
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
Herbert's chart lists the following medications: 
- Furosemide (a diuretic, also called a “water pill”) 
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

//ALL TOPICS CLICKABLES MAIN HUB
=== Ask_Patient_Questions ===
{switchState("interview")}
Ask Herbert a question.
Current empathy: {empathy} #empathyscore


* [Ask about main complaint] -> Main_Complaint
* [Ask about other symptoms] -> Other_Symptoms_Question
* [Ask about diet] -> Diet_Question
* [Ask about drinking habits] -> Drinking_Question

//TO ASK THE GROUP -- do we want questions to be repeatable or do we want them to diseappar? chart are now sticky but main topics disappear after one click

+ { bloodpressure_chart_question } [Ask about his blood pressure] -> bloodpressure_Convo
+ { heartrate_chart_question } [Ask about his heart rate] -> heartrate_Convo
+ { oxygen_chart_question } [Ask about his oxygen] -> oxygen_Convo
+ { history_chart_question } [Ask about his medical history] -> History_Convo
+ { age_chart_question } [Ask about his age] -> Age_Convo
+ { medications_chart_question } [Ask about his medications] -> Medications_Convo

//esteban's button idea (kinda clunky how the check is beign done tho...
+ { not bloodpressure_chart_question or not heartrate_chart_question or not oxygen_chart_question or not history_chart_question or not age_chart_question or not medications_chart_question } [Review the chart for more information] #checkchartagain -> Look_at_Chart 
+ [Return to the Scene 1 menu] -> Scene1_Player_Decision

//ALL TOPICS CLICKABLE BRANCHES
=== Main_Complaint ===
Player: So, it says here you’ve been having trouble breathing.
~ main_complaint_topics_question = true
+ [How would you rate your difficulty breathing on a scale of 1 to 10?] 
    -> Main_Complaint_Response_1
+ [Is there anything else you want to tell us?] 
    ->  Main_Complaint_Response_2
+ [“I'm sure it's nothing to worry about. Can you breathe okay now?”] 
    ~ give_empathy(-1, Main_Complaint == 1)
    -> Main_Complaint_Response_3

=== Main_Complaint_Response_1 ===
Herbert: On a scale of 1 to 10?
Herbert: Well, I guess a 7 or 8.
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("GOOD JOB!")

=== Main_Complaint_Response_2 ===
Herbert looks like he wants to say more...but doesn't.
Herbert: No. That’s right.
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Ask open-ended questions instead of leading questions")

=== Main_Complaint_Response_3 ===
Herbert: Yeah, it’s not that bad. I’ve gotten pretty used to it at this point. 
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Ask open-ended questions instead of leading questions")

=== Other_Symptoms_Question ===
Player: After taking a look at your chart...
~other_complaint_topics_question =true
+ ["I'd like to know if there are any symptoms I may have missed.] 
-> Other_Symptoms_Question_Response_1
+ ["Are you feeling any other symptoms?"] 
-> Other_Symptoms_Question_Response_2
+ ["I'd like to get your other symptoms from you."] 
-> Other_Symptoms_Question_Response_3

=== Other_Symptoms_Question_Response_1 ===
Herbert: There’s something in my chest. I keep coughing.
Current empathy: {empathy} #empathyscore
-> Other_Symptoms_Question_2

=== Other_Symptoms_Question_Response_2 ===
Herbert: Yeah. Mostly the breathing thing.
Current empathy: {empathy} #empathyscore
+ [Continue] -> Nurse_Feedback("You won’t get as much info by asking yes or no questions")

=== Other_Symptoms_Question_Response_3 ===
Herbert nods.
He didn’t understand that as a question.
Current empathy: {empathy} #empathyscore
+ [Continue] -> Nurse_Feedback("You won’t get as much info by asking yes or no questions")

=== Other_Symptoms_Question_2 ===
Player: That sounds concerning. If you don't mind me asking...
+ ["When did that start?"] -> Other_Symptoms_Question_2_Response_1
+ {not water_asked}["Would you like some water?"]
    ~ water_asked = true

    -> Other_Symptoms_Question_2_Response_2
+ [Where does it hurt?] -> Other_Symptoms_Question_2_Response_3

=== Other_Symptoms_Question_2_Response_1 ===
Herbert: Well, about 4 days ago I think. 
Player: Interesting. I'll note that down for later. 
Current empathy: {empathy} #empathyscore
+ [Continue] -> Ask_Patient_Questions

=== Other_Symptoms_Question_2_Response_3 ===
Player: Can you point to exactly where your chest hurts?
Herbert points his mid-sternal region.
Player: I see. Let me just write that down quickly. 
Current empathy: {empathy} #empathyscore
+ [Continue] -> Ask_Patient_Questions

=== Other_Symptoms_Question_2_Response_2 ===
Herbert: No, I’m okay, thanks. 
Player: Just making sure. Let's move on.
Current empathy: {empathy} #empathyscore
+ [Continue] -> Other_Symptoms_Question_2

=== Diet_Question ===
Player: I wanted to ask a little bit more about your diet...
+ [What do you typically eat?] 
-> Diet_Question_Response_1
+ [I think we need to talk about your weight.]
-> Diet_Question_Response_2
+ [Do you think you'd consider your diet to be healthy?] 
-> Diet_Question_Response_3

=== Diet_Question_Response_1 ===
{ Diet_Question > 1:
    Herbert: Like I already said... #angry #repeat_question
}
Herbert: I mostly eat frozen dinners, chips, pizza. 
Herbert:...not the best diet, I know. 
Current empathy: {empathy} #empathyscore
+ {not wife_topics_question}[Continue] -> Diet_Question_2
+ {wife_topics_question}[Let's talk about something else.] -> Ask_Patient_Questions //might need to DOUBLE CHECK is THIS how are we locking paths?

=== Diet_Question_Response_2 ===
Herbert: Are you calling me FAT!?
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Avoid sounding judgemental or condescending.")

=== Diet_Question_Response_3 ===
Herbert: Yeah. I guess. 
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("You won’t get as much info by asking yes or no questions``.")
=== Diet_Question_2 ===
~ wife_topics_question = true
+ [I hope you're taking care of yourself.] 
    ~ give_empathy(1, Diet_Question_2 == 1) //
    -> Diet_Question_2_Response_1
+ ["Any fruits or vegetables?"]
    ~ give_empathy(-1, Diet_Question_2 == 1)
    -> Diet_Question_2_Response_2

== Diet_Question_2_Response_1 ===
~wife_topics_question = true
Herbert: I'm...trying my best. 
Herbert: My wife died a few months ago, and things sort of went downhill from there. 
Current empathy: {empathy} #empathyscore
-> Wife_Question

== Diet_Question_2_Response_2 ===
Herbert: …I eat potatoes sometimes, if that counts.
Herbert: I'm sorry, what exactly is the point of this question?
Current empathy: {empathy} #empathyscore
+ [Continue] -> Nurse_Feedback("Avoid sounding judgemental or condescending.")

=== Wife_Question ===
+ [(Let him keep talking)]
    -> Wife_Question_Response_1
+ [Can we talk about something else?]
    ~ give_empathy(-1, Wife_Question == 1) 
    -> Wife_Question_Response_2

=== Wife_Question_Response_1 ===
Herbert: It makes no sense. She was never sick, always the one taking care of me. But the cancer was just so quick...
Current empathy: {empathy} #empathyscore
-> Wife_Question_2

=== Wife_Question_Response_2 ===
Player: Actually, let’s get back to the assessment. 
Herbert: Yeah...I'm just rambling anyway.
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Listen closely to what patients share with you.")

=== Wife_Question_2 ===
+ ["I'm sorry to hear that. I'm sure she's in a better place."]
    ~ give_empathy(-1, Wife_Question_2 == 1) 
    -> Wife_Question_2_Response_1
+ ["How has that impacted your daily life?"]
 
    -> Wife_Question_2_Response_2

=== Wife_Question_2_Response_1 ===
Herbert: Better place? Without me? I didn't come here for therapy. 
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Listen closely to what patients share with you.")

=== Wife_Question_2_Response_2 ===
Herbert: I try to manage the best I can, but it's hard without her around. She always did all the cooking. 
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Good job!")

=== Drinking_Question ===
Player: If you don't mind me asking...
~ drinking_topics_question = true
+ ["Do you drink alcohol?"] -> Drinking_Question_Response_1
+ ["How much alcohol do you drink in a day?"] -> Drinking_Question_Response_2
+ ["What have you been drinking lately?"] -> Drinking_Question_Response_1

=== Drinking_Question_Response_1 ===
Herbert: Yeah, a little.
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("You won’t get as much info by asking yes or no questions.")

=== Drinking_Question_Response_2 ===
Herbert: I used to do just a couple beers, but lately it’s been more like 3 or 4…and a glass of wine.
Current empathy: {empathy} #empathyscore

+ {not wife_topics_question}[Continue] -> Drinking_Question_2
+ {wife_topics_question}[Continue] -> Ask_Patient_Questions

=== Drinking_Question_2 ===
~ wife_topics_question = true
+ ["Why have you been drinking more recently?"]
    ~ give_empathy(1, Drinking_Question_2 == 1) 
    -> Drinking_Question_2_Response_1
+ ["Have you tried to cut back on that?"]
    ~ give_empathy(-1, Drinking_Question_2 == 1) 
    -> Drinking_Question_2_Response_2

=== Drinking_Question_Response_3 ===
Herbert: Orange juice, coke, water.
Current empathy: {empathy} #empathyscore

-> Ask_Patient_Questions

=== Drinking_Question_2_Response_1 ===
Herbert: My wife died three months ago, and things sort of went downhill from there. 
Current empathy: {empathy} #empathyscore

->Wife_Question

=== Drinking_Question_2_Response_2 ===
Herbert: Of course. It’s just hard. #angry
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Avoid sounding judgemental or condescending.")

///ALL OF THE CHART UNLOCKED CONVO STUFF
=== Medications_Convo ===
Player: I noticed on your chart you're taking some medications. 
{ Medications_Convo > 1:
    Herbert: Not this question again...! #angry #repeat_question
}
Herbert: And if I am?
~ medications_question_asked = true
Current empathy: {empathy} #empathyscore

+ [How often are you taking them?] Player: How often are you taking them?
    ~ give_empathy(1, Medications_Convo == 1) 
    -> Meds_Convo_Response_1
+ [Do you take them regularly?] Player: Do you take them regularly?

    -> Meds_Convo_Response_2
+ [What medications did you stop taking?] Player: What medications did you stop taking?
    ~ give_empathy(-1, Medications_Convo == 1)
    -> Meds_Convo_Response_3


=== Meds_Convo_Response_1 ===
{ Medications_Convo > 1:
    Herbert: ...I already said! #angry #repeat_question
}
Herbert: ....four times a week? Maybe twice a week? I think?
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
Herbert: Are you accusing me of skipping my medicine? #angry 
{ Medications_Convo > 1:
    Herbert: AGAIN!?  #angry #repeat_question
}
Herbert: I'm not careless! #angry
Herbert feels insulted.  
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Careful with how you phrase leading questions, especially if it might come off as rude.")

// MEDICAL HISTORY (with the hidden EF 30% branch)
=== History_Convo ===
Player: It says here on your chart that your last visit was a month ago. 

{ History_Convo > 1:
    Herbert: Not this question again... #angry #repeat_question
}
Herbert: I had a different issue back then and it was for nothing important, really.
~ history_question_asked = true
Current empathy: {empathy} #empathyscore

+ [If you say so.] Player: If you say so.

    -> history_Convo_Response_1
+ [Please, I'd like to hear more about it.] Player: Please, I'd like to hear more about it.
    ~ give_empathy(1, History_Convo == 1) 
    -> history_Convo_Response_2
+ [You must come here a lot.] Player: You must come here a lot.
    ~ give_empathy(-1, History_Convo == 1)
    -> history_Convo_Response_3

=== history_Convo_Response_1 ===
Herbert doesn't say more on the matter. 
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Try to dig deeper and use open-ended questions when communicating with patients.")

=== history_Convo_Response_2 === 
{ History_Convo > 1:
    Herbert: Like I said... #angry #repeat_question
}
Herbert: It wasn't for anything major. But I was told I had to get my heart checked. 
Current empathy: {empathy} #empathyscore


+ [Did they check for the volumetric fraction of blood during ejection?] 
    -> history_hidden_Response_1
+ [That sounds important. Do you remember anything your doctor might have said?] 
    -> history_hidden_Response_2


=== history_hidden_Response_1 ===
Herbert looks unsure but nods. 
Herbert: Maybe?
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Try to use familiar language and terminology when speaking with patients.")

=== history_hidden_Response_2 ===
Herbert: Not really, but maybe it's on my chart. 
After double checking the chart, you realize that there is a note of EF 30%. 

~ history_EF_question_discovered = true
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("GOOD JOB!")


=== history_Convo_Response_3 ===
Herbert frowns. 
Herbert: Not out of choice. #angry
Herbert: No one likes being sick. 
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Avoid making comments that could be interpreted as judgemental or condescending.")


=== oxygen_Convo ===
Player: On your chart, I can see they already tested your oxygen levels. 

{ oxygen_Convo > 1:
    Herbert: This again? #angry #repeat_question
}
Herbert: Are my numbers bad or something?
~ oxygen_question_asked = true
Current empathy: {empathy} #empathyscore
+ [Yes. Your oxygen levels are lower than normal.] Player: Yes. Your oxygen levels are lower than normal.
    ~ give_empathy(-1, oxygen_Convo == 1)
    -> oxygen_Convo_Response_1
+ [Your oxygen levels are perfectly fine for someone of your age.] Player: Your oxygen levels are perfectly fine for someone of your age.
    ~ give_empathy(-1, oxygen_Convo == 1)
    -> oxygen_Convo_Response_2
+ [I know you're worried, so let me first explain things further.] Player: I know you're worried, so let me first explain things further.
    ~ give_empathy(1, oxygen_Convo == 1)
    -> oxygen_Convo_Response_3


=== oxygen_Convo_Response_1 ===
Herbert looks panicked. 
Herbert: Oh god. This is exactly what the internet told me.
Herbert:...I'm dying, aren't I?
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Try not to label any details or prognosis as 'bad', for this can panic your patients.")


=== oxygen_Convo_Response_2 ===
Herbert: That still doesn't make sense. 
Herbert: Why am I having a hard time breathing then?
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Please do not lie to your patients, even if you are trying to make them feel better.")


=== oxygen_Convo_Response_3 ===
Player: Multiple factors can play into this. 
Player: So before we make any assumptions, do you mind me asking more questions?
Current empathy: {empathy} #empathyscore

+ [Continue] -> oxygen_hidden_response_0


=== oxygen_hidden_response_0 ===

Player: I wanted to ask...
Current empathy: {empathy} #empathyscore

+ [It sounds like you smoke a lot.] 
    -> oxygen_hidden_Smoking
+ [At any point, have you been exposed to a lot of smoke?] 
    -> oxygen_hidden_Firefighter


=== oxygen_hidden_Smoking ===
Herbert: And so what if I do? Is it a crime to smoke now? 
You discover Herbert's previous smoking habits. #system_message
You may want to note this for later. #system_message
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Avoid making comments that could be interpreted as judgemental or condescending.")


=== oxygen_hidden_Firefighter ===

Herbert: I did, actually. I used to work as a firefighter. And, to be honest, I used to smoke a lot too, but I try not to now. 
You discover Herbert's previous occupation and smoking habits. #system_message
You may want to note this for later. #system_message
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("GOOD JOB!")

=== Age_Convo ===
Player: Just to review, let's go over some basic information on your chart. 
{ Age_Convo > 1:
    Herbert: This again? I already told you. #angry #repeat_question 
    Player: Just humor me, please. 
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
Herbert: Older than you, that's for sure. #angry 
Herbert: Why are you asking me this? #angry
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Be clear and professional when asking questions.")

=== heartrate_Convo ===
Player: I saw on your chart that someone was able to take down your heart rate. 
Player: And I see here that they noted a S3 Gallop at Apex.

{ heartrate_Convo > 1:
    Herbert: Are you seriously asking this again? #angry #repeat_question
    Player: Yes...? 
- else:
    Herbert: Excuse me?
}
~ heartrate_question_asked = true
Current empathy: {empathy} #empathyscore

+ [It just means that there was an extra heart sound indicating ventricular overload] Player: It just means that there was an extra heart sound indicating ventricular overload.
    ~ give_empathy(-1, heartrate_Convo == 1) 
    -> heartrate_Convo_Response_1
+ [Let's just say it's a good thing you came here to get help.] Player: Let's just say it's a good thing you came here to get help.
    ~ give_empathy(-1, heartrate_Convo == 1)
    -> heartrate_Convo_Response_2
+ [Your heart is working harder than what might be considered normal.] Player: Your heart is working harder than what might be considered normal.
    ~ give_empathy(1, heartrate_Convo == 1) 
    -> heartrate_Convo_Response_3

=== heartrate_Convo_Response_1 ===
Herbert: Whatever you say. 
Herbert looks absolutely confused, but doesn't say more. 
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Try to use familiar language and terminology when speaking with patients.")


=== heartrate_Convo_Response_2 ===
Herbert: Whatever. #angry 
Herbert looks annoyed but doesn't say more. #angry 
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Avoiding an explanation can come off as rude.")


=== heartrate_Convo_Response_3 ===
Herbert: Is that what it means? That's good to know. #happy 
Player: It is. You don't need to memorize the numbers or the terms, but it's always good to be self-aware of your condition.
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("GOOD JOB!")


=== bloodpressure_Convo ===
Player: Looking at your chart, I noticed your blood pressure was taken.
{ bloodpressure_Convo > 1:
    Herbert: Again with the blood pressure? #angry #repeat_question
}
Herbert: Yes it was. What's the verdict?
~ bloodpressure_question_asked = true
Current empathy: {empathy} #empathyscore

+ [Based on what I'm seeing, your blood pressure is a slightly higher than usual.] Player: Based on what I'm seeing, your blood pressure is a slightly higher than usual.
    ~ give_empathy(1, bloodpressure_Convo == 1) 
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
Herbert: Sounds like a plan. #happy
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("GOOD JOB!")


=== bloodpressure_Convo_Response_2 ===
Herbert: ...I guess that's...interesting?
Player: Not to worry. We'll first cross-check it with the rest of your medical details before coming to any conclusions.
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Try to use familiar language and terminology when speaking with patients.")


=== bloodpressure_Convo_Response_3 ===
Herbert: Okay...whatever you say...? 
Player: Moving on!
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Try to use familiar language and terminology when speaking with patients.")

=== Patient_Physical ===
CURRENTLY IN PROGRESS... 
-> END

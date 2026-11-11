VAR empathy = 0
VAR water_asked = false
VAR wife_asked = false
VAR showering = false
VAR main_complaint = false

-> MainQuestions_Introduction

=== MainQuestions_Introduction ===
* [Ask about main complaint] -> Main_Complaint
* [Ask about other symptoms] -> Other_Symptoms_Question
* [Ask about diet] -> Diet_Question
* [Ask about drinking habits] -> Drinking_Question
+ [Proceed to physical exam(Scene 2)] -> PhysicalExam

=== Nurse_Feedback(line) ===
Nurse: {line} #nursenotification

+ [Continue] -> MainQuestions_Introduction

=== function give_empathy(amount, count_it) ===
{ count_it:
    ~ empathy = empathy + amount
}

=== Main_Complaint ===
Player: So, it says here you’ve been having trouble breathing.
~ main_complaint = true
+ [Ask him to rate his difficulty breathing]
    ~ give_empathy(1, Main_Complaint == 1)
    -> Main_Complaint_Response_1
+ [Ask if he wants to add anything] -> Main_Complaint_Response_2
+ [“I'm sure it's nothing to worry about. Can you breathe okay now?”]
    ~ give_empathy(-1, Main_Complaint == 1)
    -> Main_Complaint_Response_3

=== Main_Complaint_Response_1 ===
Player: How would you rate your difficulty breathing on a scale of 1 to 10? #empathy+1
Herbert: Well, I guess a 7 or 8.
Current empathy: {empathy} #empathyscore

-> Breathing_Question

=== Main_Complaint_Response_2 ===
Player: Is there anything you want to add to that?
Herbert: No. That’s right.
Current empathy: {empathy} #empathyscore
Nurse: You won’t get as much info by asking yes or no questions #nursenotification

-> Breathing_Question

=== Main_Complaint_Response_3 ===
Herbert: Yeah, it’s not that bad. I’ve gotten pretty used to it at this point. #empathy-1
Current empathy: {empathy} #empathyscore
Nurse: Ask open-ended questions instead of leading questions #nursenotification

-> Breathing_Question

=== Breathing_Question ===
+ [Ask about day-to-day] -> Breathing_Question_Response_1
    ~ give_empathy(1, Breathing_Question == 1)
+ [“Is that it?”] -> Breathing_Question_Response_2
+ [Ask about struggles]
    ~ give_empathy(-1, Breathing_Question == 1)
    -> Breathing_Question_Response_3

=== Breathing_Question_Response_1 ===
Player: Could you tell me a little more about what’s been going on day-to-day? #empathy+1
Herbert: It’s been hard to make food or even shower. Just…little things take a lot of energy.
Current empathy: {empathy} #empathyscore
~ showering = true

-> Breathing_Question_2

=== Breathing_Question_Response_2 ===
Herbert: Yeah, that’s about it.
Current empathy: {empathy} #empathyscore

Nurse: Ask open-ended questions instead of leading questions #nursenotification
-> Breathing_Question_2

=== Breathing_Question_Response_3 ===
Player: How else have you been struggling? #empathy-1
Herbert: I’m not struggling. It’s just…little things take a lot of energy these days.
Current empathy: {empathy} #empathyscore

Nurse: Avoid sounding judgmental or condescending #nursenotification
-> Breathing_Question_2

=== Breathing_Question_2 ===
+ ["Have you been able to eat anything lately?"]
    ~ give_empathy(1, Breathing_Question_2 == 1)
    -> Breathing_Question_2_Response_1
+ {showering}[Ask about showering] -> Breathing_Question_2_Response_2
+ ["I imagine you've been eating lots of junk food?"]
    ~ give_empathy(-2, Breathing_Question_2 == 1)
    -> Breathing_Question_2_Response_3

=== Breathing_Question_2_Response_1 ===
Herbert: Not much, but my stomach feels pretty heavy. #empathy+1
Current empathy: {empathy} #empathyscore

->MainQuestions_Introduction

=== Breathing_Question_2_Response_2 ===
Player: How have you been showering?
Herbert. Uh...I don’t know what you mean.
Current empathy: {empathy} #empathyscore

->MainQuestions_Introduction

=== Breathing_Question_2_Response_3 ===
Herbert: I’m just doing my best. #empathy-1 #angry
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Avoid sounding judgmental or condescending.")

=== Other_Symptoms_Question ===
+ ["Are you feeling any other symptoms?"] -> Other_Symptoms_Question_Response_1
+ ["I don't see any more symptoms in your file. Correct?] -> Other_Symptoms_Question_Response_2
+ ["I'd like to get your other symptoms from you."] -> Other_Symptoms_Question_Response_3

=== Other_Symptoms_Question_Response_1 ===
Herbert: There’s something in my chest. I keep coughing.
Current empathy: {empathy} #empathyscore

-> Other_Symptoms_Question_2

=== Other_Symptoms_Question_Response_2 ===
Herbert: Yeah. Mostly the breathing thing.
Current empathy: {empathy} #empathyscore
Nurse: You won’t get as much info by asking yes or no questions #nursenotification

-> Other_Symptoms_Question_2

=== Other_Symptoms_Question_Response_3 ===
Herbert nods.
He didn’t understand that as a question.
Current empathy: {empathy} #empathyscore

-> MainQuestions_Introduction

=== Other_Symptoms_Question_2 ===
+ ["When did that start?"] -> Other_Symptoms_Question_2_Response_1
+ {not water_asked}["Would you like some water?"]
    ~ water_asked = true
    ~ give_empathy(1, Other_Symptoms_Question_2 == 1)
    -> Other_Symptoms_Question_2_Response_2
+ [Ask where it hurts] -> Other_Symptoms_Question_2_Response_3

=== Other_Symptoms_Question_2_Response_1 ===
Herbert: Well, about 4 days ago I think.
Current empathy: {empathy} #empathyscore

-> MainQuestions_Introduction

=== Other_Symptoms_Question_2_Response_2 ===
Herbert: No, I’m okay, thanks. #empathy+1
Current empathy: {empathy} #empathyscore

+ ["Are you sure? It's no trouble"]
    ~ give_empathy(-1, Other_Symptoms_Question_2_Response_2 == 1)
    -> Water_Question_Response_1
+ [Okay, just let me know"] -> Water_Question_Response_2
    ~ give_empathy(1, Other_Symptoms_Question_2_Response_2 == 1)

=== Water_Question_Response_1 ===
Herbert: I said I’m good. #empathy-1 #angry
He suddenly starts coughing.
Current empathy: {empathy} #empathyscore

-> Water_Question_2

=== Water_Question_Response_2 ===
Herbert: Thanks. #empathy+1
Herbert suddenly starts coughing.
Current empathy: {empathy} #empathyscore

-> Water_Question_2

=== Water_Question_2 ===
+ {water_asked}[Bring him water. Joke, "See, you did need water"]
    ~ give_empathy(-2, Water_Question_2 == 1)
    -> Water_Question_2_Response_1
+ [Bring him water]
    ~ give_empathy(2, Water_Question_2 == 1)
    -> Water_Question_2_Response_2
+ [Don't bring him water]
    ~ give_empathy(-1, Water_Question_2 == 1)
    -> Water_Question_2_Response_3

=== Water_Question_2_Response_1 ===
You bring him a cup of water. #empathy-2 #angry
Player: Looks like you did need water.
Herbert looks annoyed and embarrassed.
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Don’t say something that could come off as rude.")

=== Water_Question_2_Response_2 ===
You bring him a cup of water. #empathy+2 #happy
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Good job!")

=== Water_Question_2_Response_3 ===
Herbert continues coughing. #empathy-1
Herbert: Sorry.
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Recognize when patients are uncomfortable and help.")

=== Other_Symptoms_Question_2_Response_3 ===
Player: Can you point to exactly where your chest hurts?
Herbert points to the mid-sternal region.
Current empathy: {empathy} #empathyscore

-> MainQuestions_Introduction

=== Diet_Question ===
+ [What do you typically eat?] -> Diet_Question_Response_1
+ [What is your diet?] -> Diet_Question_Response_2
+ [Overall, would you say you eat healthy?] -> Diet_Question_Response_2

=== Diet_Question_Response_1 ===
Herbert: Mostly frozen dinners, chips, pizza. I haven’t been taking very good care of myself lately.
Current empathy: {empathy} #empathyscore

+ {not wife_asked}[Continue] -> Diet_Question_2
+ {wife_asked}[Continue] -> MainQuestions_Introduction

=== Diet_Question_2 ===
+ ["Taking care of yourself?"]
    ~ give_empathy(1, Diet_Question_2 == 1)
    -> Diet_Question_2_Response_1
+ ["Any fruits or vegetables?"]
    ~ give_empathy(-1, Diet_Question_2 == 1)
    -> Diet_Question_2_Response_2

== Diet_Question_2_Response_1 ===
Player: Is there a reason you stopped taking good care of yourself? #empathy+1
Herbert: My wife died a few months ago, and things sort of went downhill from there.
Current empathy: {empathy} #empathyscore

-> Wife_Question

== Diet_Question_2_Response_2 ===
Herbert: No…I eat potatoes sometimes, if that counts. #empathy-1
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Avoid sounding judgemental or condescending.")

=== Wife_Question ===
+ [Let him keep talking]
    ~empathy = empathy + 2
    -> Wife_Question_Response_1
+ [Change the subject]
    ~empathy = empathy - 2
    -> Wife_Question_Response_2

=== Wife_Question_Response_1 ===
Herbert: It makes no sense. She was never sick, always the one taking care of me. Then she dies of pancreatic cancer. #empathy+2
Current empathy: {empathy} #empathyscore

-> Wife_Question_2

=== Wife_Question_Response_2 ===
Player: I shouldn't have brought that up. Let’s get back to the assessment. #empathy-2
Herbert: Yeah...I'm just rambling anyway.
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Listen closely to what patients share with you.")

=== Wife_Question_2 ===
+ ["I'm sorry to hear that. I'm sure she's in a better place."]
    ~ give_empathy(-2, Wife_Question_2 == 1)
    -> Wife_Question_2_Response_1
+ ["How has that impacted your daily life?"]
    ~ give_empathy(1, Wife_Question_2 == 1)
    -> Wife_Question_2_Response_2

=== Wife_Question_2_Response_1 ===
Herbert: Better place? Without me? I didn't come here for therapy. #empathy-2 #angry
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Listen closely to what patients share with you.")

=== Wife_Question_2_Response_2 ===
Herbert: I try to manage the best I can, but it's hard without her around. She always did all the cooking. #empathy+1
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Good job!")

=== Diet_Question_Response_2 ===
Herbert: I’m not really on any sort of diet. If you couldn’t tell.
Current empathy: {empathy} #empathyscore

-> MainQuestions_Introduction

=== Diet_Question_Response_3 ===
Herbert: Yeah I guess. I could probably do better.
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Avoid sounding judgemental or condescending.")

=== Drinking_Question ===
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

+ {not wife_asked}[Continue] -> Drinking_Question_2
+ {wife_asked}[Continue] -> MainQuestions_Introduction
=== Drinking_Question_2 ===
+ ["Why have you been drinking more recently?"]
    ~ give_empathy(1, Wife_Question_2 == 1)
    -> Drinking_Question_2_Response_1
+ ["Have you tried to cut back on that?"] -> Drinking_Question_2_Response_2
    ~ give_empathy(-1, Wife_Question_2 == 1)

=== Drinking_Question_Response_3 ===
Herbert: Orange juice, coke, water.
Current empathy: {empathy} #empathyscore

-> MainQuestions_Introduction

=== Drinking_Question_2_Response_1 ===
Herbert: My wife died three months ago, and things sort of went downhill from there. #empathy+1
Current empathy: {empathy} #empathyscore

->Wife_Question

=== Drinking_Question_2_Response_2 ===
Herbert: Of course. It’s just hard. #empathy-1 #angry
Current empathy: {empathy} #empathyscore

+ [Continue] -> Nurse_Feedback("Avoid sounding judgemental or condescending.")
    
=== PhysicalExam ===

-> END
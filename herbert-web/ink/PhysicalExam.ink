VAR scalyPlaques_examined = false
VAR JVD_examined = false
VAR S3gallop_examined = false
VAR clubbing_examined = false
VAR bibasilarCrackles_examined = false
VAR empathy = 0

// [web] Same convention as ChartAndInterview.ink: the web app listens for this.
EXTERNAL switchState(stateName)

// [web] Entry point (the Unity copy has no top-level divert).
-> Ask_Permission_Examine_Question

=== Nurse_Feedback(line) ===
Nurse: {line} #nursenotification 
+ [Continue] -> Physical_Exam

=== function give_empathy(amount, count_it) ===
{ count_it:
    ~ empathy = empathy + amount
}

=== Ask_Permission_Examine_Question ===
Player: For this part of the examination, I need to take a closer look at your torso.
+ [Do you mind if I touch you?]
    ~ give_empathy(1, Ask_Permission_Examine_Question == 1)
    -> Examine_Torso_Response_1
+ [I’m sorry if this makes you feel uncomfortable or awkward, but may I please touch you?]
    ~ give_empathy(-1, Ask_Permission_Examine_Question == 1)
    -> Examine_Torso_Response_2
* [Please remain still while I examine your body]
    ~ give_empathy(-1, Ask_Permission_Examine_Question == 1)
    -> Examine_Torso_Response_3

=== Examine_Torso_Response_1 ===
Herbert: Sure thing. 
Current empathy: {empathy} #empathyscore
+ [Continue] -> Nurse_Feedback("Good job!")

=== Examine_Torso_Response_2 ===
Herbert: It’s fine. I'm not a kid. #angry
Herbert huffs and removes his shirt quickly.
Current empathy: {empathy} #empathyscore
+ [Continue] -> Nurse_Feedback("Avoid sounding judgemental or condescending.")

=== Examine_Torso_Response_3 ===
Herbert: Would it have killed you to ask before touching me? #angry
Current empathy: {empathy} #empathyscore
+ [Continue] -> Nurse_Feedback("Ask patients for consent before physical touch.")

/// These show up after clicking physical symptoms

=== Physical_Exam ===
{switchState("explore")}
+ [Scaly plaques] -> ScalyPlaques_Question
+ [Abdomen swelling] -> Abdomen_Question
+ [S3 Gallop] -> S3Gallop_Question
+ [Jugular venous distension] -> JVD_Question
+ [Clubbing] -> Clubbing_Question
+ [Bibasilar crackles] -> BibasilarCrackles_Question
+ [END EXAM] -> End_Exam

=== Abdomen_Question ===
Player: There's some swelling in your abdomen.
Herbert: Why is that happening?

+ [This is what happens when you skip your water pill] -> Abdomen_Response_1
    ~ give_empathy(-1, Abdomen_Question == 1)
+ [You've been retaining fluid more than normal] -> Abdomen_Response_2
+ [If you ate more vegetables it would go away] -> Abdomen_Response_3
    ~ give_empathy(-1, Abdomen_Question == 1)

=== Abdomen_Response_1 ===
Herbert looks ashamed.
+ [Continue] -> Nurse_Feedback("Avoid being judgemental or condescending.")

=== Abdomen_Response_2 ===
Herbert: Is that why my weight has gone up?
Player: It certainly could be.
+ [Continue] -> Nurse_Feedback("Good job!")

=== Abdomen_Response_3 ===
Herbert: Really?
Herbert looks skeptical.
+ [Continue] -> Nurse_Feedback("Do not lie to patients, even to convince them to change their habits.")

=== ScalyPlaques_Question ===
Player: I notice some scaly plaques on your side.
~ scalyPlaques_examined = true
+ [That must be so painful for you.]
    ~ give_empathy(-1, ScalyPlaques_Question == 1)
    -> ScalyPlaques_Response_1
+ [How long have you had this for?]
    -> ScalyPlaques_Response_2
+ [Have you noticed this anywhere else?]
    -> ScalyPlaques_Response_3

=== ScalyPlaques_Response_1===
Herbert: I'm tougher than you think I am.
Current empathy: {empathy} #empathyscore
+ [Continue] -> Physical_Exam

=== ScalyPlaques_Response_2 ===
Herbert: A few months at least.
+ [Continue] -> Physical_Exam

=== ScalyPlaques_Response_3 ===
Herbert: No, just here.
+ [Continue] -> Physical_Exam

/////// this would be redundant with Heart Rate chart question
=== S3Gallop_Question ===
Player: I’m hearing an S3 Gallop.
Herbert: What’s that?
~ S3gallop_examined = true
+ [It’s a tertiary low-frequency vibration in the left or right ventricle] -> S3Gallop_Response_1
+ [Basically, it’s a third heart beat that means your heart is working harder than usual]
    ~ give_empathy(1, S3Gallop_Question == 1)
-> S3Gallop_Response_2
+ [All you need to know is that it’s abnormal and could cause problems]
   	~ give_empathy(-1, S3Gallop_Question == 1)
-> S3Gallop_Response_3

=== S3Gallop_Response_1 ===
Herbert nods along, but looks absolutely confused.
+ [Continue] -> Nurse_Feedback("Use familiar language instead of clinical terms.")

=== S3Gallop_Response_2 ===
Herbert: Okay. Makes sense.
Current empathy: {empathy} #empathyscore
+ [Continue] -> Physical_Exam

=== S3Gallop_Response_3 ===
Herbert: Oh…
He looks scared.
Current empathy: {empathy} #empathyscore
+ [Continue] -> Nurse_Feedback("Try to avoid worrying patients.")

=== JVD_Question ===
Player: Could I get you to tilt forward a bit?
Herbert: Okay.
Player: I notice a distention here on your neck.
Herbert: You mean the lump? What does it mean?
~ JVD_examined = true
* [Nothing, it’s probably just some age-related swelling] -> JVD_Response_1
* [It means blood might be backed up here. Do you find it harder to breathe at this angle?] -> JVD_Response_2
* [It means you have a 5cm jugular venous distention at a 45 degree angle] -> JVD_Response_3

=== JVD_Response_1 ===
Herbert: Phew. I was a bit worried about that.
+ [Continue] -> Nurse_Feedback("Do not lie to patients, even to make them feel better.")

=== JVD_Response_2 ===
Herbert: Yes it’s much harder.
Player: Okay, I’ll note that.
+ [Continue] -> Nurse_Feedback("Good job!")

=== JVD_Response_3 ===
Herbert looks completely lost.
+ [Continue] -> Nurse_Feedback("Use familiar language instead of clinical terms.")

=== Clubbing_Question === 
Player: It looks like there’s some clubbing in the fingers.
Herbert: Huh?
~ clubbing_examined = true
+ [It’s often caused by low oxygen levels] -> Clubbing_Response_1
+ [It’s probably just bloating. Did you have salty food recently?] -> Clubbing_Response_2
+ [You have severe digital clubbing and nail separation] -> Clubbing_Response_3

=== Clubbing_Response_1 ===
Herbert: Ah ok. Because of my breathing?
Player: That seems to be related, yes.
+ [Continue] -> Nurse_Feedback("Good job!")

=== Clubbing_Response_2 ===
Herbert: Yes. So that’s why.
+ [Continue] -> Nurse_Feedback("Do not lie to patients, even to make them feel better.")

=== Clubbing_Response_3 ===
Herbert frowns in confusion.
+ [Continue] -> Nurse_Feedback("Use familiar language instead of clinical terms.")

=== BibasilarCrackles_Question ===
Player: I hear some crackles in your lungs.
Herbert: Yeah what causes that?
~ bibasilarCrackles_examined = true
+ [It’s too complicated to explain, you probably wouldn’t understand] -> Crackles_Response_1
    ~ give_empathy(-1, BibasilarCrackles_Question == 1)
+ [It’s basically fluid build-up in the lungs] -> Crackles_Response_2
    ~ give_empathy(1, BibasilarCrackles_Question == 1)
+ [Frankly it means your lungs may be permanently damaged] -> Crackles_Response_3

=== Crackles_Response_1 ===
Herbert: I’m as stupid as you think. #angry
Current empathy: {empathy} #empathyscore
+ [Continue] -> Nurse_Feedback("Avoid sounding judgemental or condescending.")

=== Crackles_Response_2 ===
Herbert nods.
+ [Continue] -> Physical_Exam

=== Crackles_Response_3 ===
Herbert looks concerned.
Current empathy: {empathy} #empathyscore
+ [Continue] -> Nurse_Feedback("Try to avoid worrying patients.")

=== End_Exam ===

->END


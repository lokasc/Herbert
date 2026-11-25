VAR scalyPlaques_examined = false
VAR JVD_examined = false
VAR S3gallop_examined = false
VAR clubbing_examined = false
VAR bibasilarCrackles_examined = false
VAR empathy = 0
VAR medications_question_asked = false
VAR oxygen_question_asked = false

PLAYER: "Hi."
+ [Continue] -> Ask_Permission_Examine_Question

=== Nurse_Feedback(line) ===
NURSE: "{line}" #nursenotification 
+ [Continue] -> Physical_Exam

=== function give_empathy(amount, count_it) ===
{ count_it:
    ~ empathy = empathy + amount
}

=== Ask_Permission_Examine_Question ===
PLAYER: "For this part of the examination, I need to take a closer look at your torso."
+ ["Do you mind if I touch you?"]
    ~ give_empathy(1, Ask_Permission_Examine_Question == 1)
    -> Examine_Torso_Response_1
+ ["I’m sorry if this makes you feel uncomfortable or awkward, but may I please have permission to touch you?"]
    ~ give_empathy(-1, Ask_Permission_Examine_Question == 1)
    -> Examine_Torso_Response_2
+ ["Please remain still while I examine your body"]
    ~ give_empathy(-1, Ask_Permission_Examine_Question == 1)
    -> Examine_Torso_Response_3

=== Examine_Torso_Response_1 ===
HERBERT: "Sure thing." 
Current empathy: {empathy} #empathyscore
+ [Continue] -> Nurse_Feedback("Good job!")

=== Examine_Torso_Response_2 ===
HERBERT: "It’s fine. I'm not a kid." #angry
Herbert huffs and removes his shirt quickly.
Current empathy: {empathy} #empathyscore
+ [Continue] -> Nurse_Feedback("Avoid sounding judgemental or condescending.")

=== Examine_Torso_Response_3 ===
HERBERT: "Would it have killed you to ask before touching me?" #angry
Current empathy: {empathy} #empathyscore
+ [Continue] -> Nurse_Feedback("Ask patients for consent before physical touch.")

/// These show up after clicking physical symptoms

=== Physical_Exam ===
* [Scaly plaques] -> ScalyPlaques_Question
* [Abdomen swelling] -> Abdomen_Question
* [Click heart/lungs] -> Heart_Lungs_Question
* [Jugular venous distension] -> JVD_Question
* [Clubbing] -> Clubbing_Question
* [Lower Extremity Swelling] -> Feet_Question
* [END EXAM] -> End_Exam

=== Heart_Lungs_Question ===
What would you like to examine?

* [Heart] -> S3Gallop_Question
* [Lungs] -> BibasilarCrackles_Question

=== Abdomen_Question ===
PLAYER: "There's some swelling in your abdomen."
HERBERT: "Why is that happening?"

+ {medications_question_asked}["This is what happens when you skip your water pill"] -> Abdomen_Response_1
    ~ give_empathy(-1, Abdomen_Question == 1)
+ {not medications_question_asked}["Have you been taking your water pill?"] -> Abdomen_Response_1_2
+ ["You've been retaining fluid more than normal"] -> Abdomen_Response_2
+ ["If you ate more vegetables it would go away"] -> Abdomen_Response_3
    ~ give_empathy(-1, Abdomen_Question == 1)

=== Abdomen_Response_1 ===
Herbert looks ashamed.
+ [Continue] -> Nurse_Feedback("Avoid being judgemental or condescending.")

=== Abdomen_Response_1_2 ===
HERBERT: "Sometimes I...skip it."
HERBERT: "It makes me get up so many times to use the bathroom."

+ [Continue] -> Physical_Exam

=== Abdomen_Response_2 ===
HERBERT: "Is that why my weight has gone up?"
PLAYER: "It certainly could be."
+ [Continue] -> Nurse_Feedback("Good job!")

=== Abdomen_Response_3 ===
HERBERT: "Really?"
Herbert looks skeptical.
+ [Continue] -> Nurse_Feedback("Do not lie to patients, even to convince them to change their habits.")

=== ScalyPlaques_Question ===
PLAYER: "I notice some scaly plaques on your side."
~ scalyPlaques_examined = true
+ ["That must be so painful for you."]
    ~ give_empathy(-1, ScalyPlaques_Question == 1)
    -> ScalyPlaques_Response_1
+ ["How long have you had this for?"]
    -> ScalyPlaques_Response_2
+ ["Have you noticed this anywhere else?"]
    -> ScalyPlaques_Response_3

=== ScalyPlaques_Response_1===
HERBERT: "I'm tougher than you think I am."
Current empathy: {empathy} #empathyscore
+ [Continue] -> Physical_Exam

=== ScalyPlaques_Response_2 ===
HERBERT: "A few months at least."
+ [Continue] -> Physical_Exam

=== ScalyPlaques_Response_3 ===
HERBERT: "No, just here."
+ [Continue] -> Physical_Exam

/////// this would be redundant with Heart Rate chart question
=== S3Gallop_Question ===
PLAYER: "I’m hearing an S3 Gallop."
HERBERT: "What’s that?"
~ S3gallop_examined = true
+ ["It’s a tertiary low-frequency vibration in the left or right ventricle"] -> S3Gallop_Response_1
+ ["Basically, it’s a third heart beat that means your heart is working harder than usual"]
    ~ give_empathy(1, S3Gallop_Question == 1)
-> S3Gallop_Response_2
+ ["All you need to know is that it’s abnormal and could cause problems"]
   	~ give_empathy(-1, S3Gallop_Question == 1)
-> S3Gallop_Response_3

=== S3Gallop_Response_1 ===
Herbert nods along, but looks absolutely confused.
+ [Continue] -> Nurse_Feedback("Use familiar language instead of clinical terms.")

=== S3Gallop_Response_2 ===
HERBERT: "Okay. Makes sense."
Current empathy: {empathy} #empathyscore
+ [Continue] -> Physical_Exam

=== S3Gallop_Response_3 ===
HERBERT: "Oh…"
Herbert looks worried.
Current empathy: {empathy} #empathyscore
+ [Continue] -> Nurse_Feedback("Try to avoid worrying patients.")

=== JVD_Question ===
PLAYER: "Could I get you to tilt backward a bit?"
HERBERT: "Okay."
PLAYER: "I notice a distention here on your neck."
HERBERT: "You mean the lump? What does it mean?"
~ JVD_examined = true
* ["Nothing, it’s probably just some age-related swelling"] -> JVD_Response_1
* ["It means blood might be backed up here. Do you find it harder to breathe at this angle?"] -> JVD_Response_2
* ["It means you have a 5cm jugular venous distention at a 45 degree angle"] -> JVD_Response_3

=== JVD_Response_1 ===
HERBERT: "Phew. I was a bit worried about that."
+ [Continue] -> Nurse_Feedback("Do not lie to patients, even to make them feel better.")

=== JVD_Response_2 ===
HERBERT: "Yes it’s much harder."
PLAYER: "Okay, I’ll note that."
+ [Continue] -> Nurse_Feedback("Good job!")

=== JVD_Response_3 ===
Herbert looks completely lost.
+ [Continue] -> Nurse_Feedback("Use familiar language instead of clinical terms.")

=== Clubbing_Question === 
PLAYER: "It looks like there’s some clubbing in the fingers."
HERBERT: "Huh?"
~ clubbing_examined = true
+ ["It’s often caused by low oxygen levels"] -> Clubbing_Response_1
+ ["It’s probably just bloating. Did you have salty food recently?"] -> Clubbing_Response_2
+ ["You have severe digital clubbing and nail separatio"] -> Clubbing_Response_3

=== Clubbing_Response_1 ===
HERBERT: "Ah ok. Because of my breathing?"
PLAYER: "That seems to be related, yes."
+ [Continue] -> Nurse_Feedback("Good job!")

=== Clubbing_Response_2 ===
HERBERT: "Yes. So that’s why."
+ [Continue] -> Nurse_Feedback("Do not lie to patients, even to make them feel better.")

=== Clubbing_Response_3 ===
Herbert frowns in confusion.
+ [Continue] -> Nurse_Feedback("Use familiar language instead of clinical terms.")

=== BibasilarCrackles_Question ===
PLAYER: "I hear some crackles in your lungs."
HERBERT: "Yeah what causes that?"
~ bibasilarCrackles_examined = true
+ ["It’s too complicated to explain, you probably wouldn’t understand"] -> Crackles_Response_1
    ~ give_empathy(-1, BibasilarCrackles_Question == 1)
+ ["It’s basically fluid build-up in the lungs"] -> Crackles_Response_2
    ~ give_empathy(1, BibasilarCrackles_Question == 1)
+ ["Frankly it means your lungs may be permanently damaged"] -> Crackles_Response_3

=== Crackles_Response_1 ===
HERBERT: "I’m as stupid as you think." #angry
Current empathy: {empathy} #empathyscore
+ [Continue] -> Nurse_Feedback("Avoid sounding judgemental or condescending.")

=== Crackles_Response_2 ===
Herbert nods.
Current empathy: {empathy} #empathyscore
+ [Continue] -> Physical_Exam

=== Crackles_Response_3 ===
Herbert looks very concerned.
+ [Continue] -> Nurse_Feedback("Try to avoid worrying patients.")

=== Feet_Question ===
PLAYER: "There's some swelling in your lower legs here."

+ ["Do you understand why this happens?"] -> Feet_Response_1
+ ["When did you first notice this?"] -> Feet_Response_2
+ ["Are you still able to walk like this?"] -> Feet_Response_3

=== Feet_Response_1 ===
HERBERT: "No...are you going to tell me?"
PLAYER: "It's probably a side effect of your body retaining fluid."
+ [Continue] -> Physical_Exam

=== Feet_Response_2 ===
HERBERT: "About the same time when my weight started going up."
+ [Continue] -> Physical_Exam

=== Feet_Response_3 ===
HERBERT: "Well I got here somehow didn't I?"
+ [Continue] -> Physical_Exam

=== End_Exam ===

->END


VAR empathy = 0
VAR medications_chart_question = false
VAR age_chart_question = false
VAR jvd_question = false
VAR strippedpatient_question = false
VAR main_question_asked = false
VAR jvd_question_asked = false
VAR medications_question_asked = false
VAR questions_asked = 0
VAR can_proceed_to_physical = false
VAR neck_observation_attempted = false
VAR torso_observation_attempted = false
VAR plaques_question_asked = false

-> Patient_Introduction

=== Patient_Introduction ===
Player: Herbert, yes? How are you? I heard you came in for a complaint regarding your breathing?
Herbert: Yes, that's me. I know it's probably nothing, but I can't ignore it anymore.
Player: I'm sorry to hear that. Let me just take a look at your chart first and see what I can do.

+ [Begin examination]
    -> Scene1_Player_Decision


=== Scene1_Player_Decision ===

What would you like to do?

+ [Look at Chart] -> Look_at_Chart
+ [Ask Patient Questions (Scene1)] -> Ask_Patient_Questions
+ {can_proceed_to_physical} [Proceed to Physical Exam (Scene2)] -> Patient_Physical

* [Return to the Scene 1 menu] -> Scene1_Player_Decision

Current empathy: {empathy}
Current questions asked: {questions_asked}



=== Look_at_Chart ===
Patient Chart

+ [Full Name] -> Full_Name
+ [Prescribed Medications] -> Prescribed_Medications
+ [Age] -> Age
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Full_Name ===
Patient Information
Full Name: Herbert Bower 

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Prescribed_Medications ===
Prescribed Medications

Herbert's chart lists the following medications:
- Furosemide
- ASA 81 mg daily
- Spironolactone
- Colace Docusate 100 mg TID
~ medications_chart_question = true

You have reviewed Herbert's medication history. You can now ask him about his medications.

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision


=== Age ===
Patient Information

Age: [Insert age]
~ age_chart_question = true

You have reviewed Herbert's age.

+ [Return to chart] -> Look_at_Chart
+ [Return to interviewing patient] -> Scene1_Player_Decision

=== Patient_Physical ===
Player: Mr. Herbert, if you would please get on the examination table, we can proceed with the physical check. 
Herbert: Sure...
Herbert looks nervous about the physical examination.
-> Scene2_Player_Decision


=== Scene2_Player_Decision ===
What would you like to do?

+ {not neck_observation_attempted} [Observe Herbert's neck] 
    ~ neck_observation_attempted = true
    -> Observe_Patient_Neck

+ {not torso_observation_attempted} [Ask Herbert to remove his shirt to examine abdomen]
    ~ torso_observation_attempted = true
    -> Observe_Patient_Abdomen

+ {strippedpatient_question and not plaques_question_asked} [Ask about the scaly plaques] -> scaly_plaques_question

+ [Proceed to Ending Assessment - You cannot return to this scene once selected] -> Proceed_to_MCQ

Current empathy: {empathy}

=== Observe_Patient_Neck ===
Observe Herbert's Neck

Herbert sits on the examination bed. As you look more closely at his neck, you notice a possible jugular venous distention (JVD).

+ {not jvd_question} [Examine the distention on Herbert's neck] -> Examine_JVD
{jvd_question:
    You have examined the finding. You can now ask Herbert about it.
}

+ [Return to examination] -> Scene2_Player_Decision


=== Examine_JVD ===
~ jvd_question = true
-> JVD_Convo

=== Observe_Patient_Abdomen ===
Player: For this part of the examination, I need to properly assess your torso. 
* [You can remove your shirt and put on this gown. I can wait outside until you are ready. ]
    ~ empathy = empathy + 1
    ~ strippedpatient_question = true
    -> Examine_Torso_Response_1
* [Just to be really really clear, I need you to remove your shirt.]
    ~ empathy = empathy - 1
    ~ strippedpatient_question = true
    -> Examine_Torso_Response_2
* [Please assume a supine position sans shirt so that I can auscultate your lungs.]
    -> Examine_Torso_Response_3

=== Examine_Torso_Response_1 ===
Herbert: Sure thing. I'll do that right now. 
When you return to the room, Herbert is ready for his physical examination. 
You notice scaly plaques on his abdomen.
 ~ empathy = empathy + 2
Current empathy: {empathy}
-> scaly_plaques_question

=== Examine_Torso_Response_2 ===
Herbert: I'm not an idiot. 
Herbert huffs and removes his shirt quickly. 
As he does, you notice scaly plaques on his abdomen.
 ~ empathy = empathy - 1
-> scaly_plaques_question

=== Examine_Torso_Response_3 ===
Herbert: Right...I think I can do that. 
Herbert does not remove his shirt. He leans back slightly.
Herbert did not understand your request. 
-> Scene2_Player_Decision

=== scaly_plaques_question ===
~ plaques_question_asked = true
Player: I noticed some plaques on your side.
* [And it looks like it's been bothering you for a while...has it been painful for you?]
    ~ empathy = empathy - 1
    -> Examine_Plaques_Response_1
* [How long have you had this?]
    ~ empathy = empathy + 1
    -> Examine_Plaques_Response_2


=== Examine_Plaques_Response_1===
Herbert: I'm fine. I'm not as weak as you think I am. 
Herbert is trying to put a tough guy act. 
-> Scene2_Player_Decision


=== Examine_Plaques_Response_2===
Herbert: Now that I think about it, I think I've had it ever since my heart problem got worse. 
A notable observation!
-> Scene2_Player_Decision

=== Ask_Patient_Questions ===
Ask Herbert a Question.
~ can_proceed_to_physical = (questions_asked > 1)

* {not main_question_asked} [Ask about his main complaint] -> Main_Convo
* {medications_chart_question and not medications_question_asked} [Ask about his medications] -> Medications_Convo
+ [Return to the Scene 1 menu] -> Scene1_Player_Decision


=== Main_Convo ===
Player: I wanted to ask about your main complaint.
Herbert: What do you mean?
Player: It says here you are dealing with difficulty breathing.
~ questions_asked = questions_asked + 1

* [Is that it?]
    ~ empathy = empathy - 1
    ~ main_question_asked = true
    -> Main_Convo_Response_1
* [Can you explain further?]
    ~ empathy = empathy + 1
    ~ main_question_asked = true
    ~ questions_asked =  questions_asked + 1
    -> Main_Convo_Response_2
* [I could use more detail.]
    ~ main_question_asked = true
    -> Main_Convo_Response_3


=== Main_Convo_Response_1 ===
Herbert: ...What, you think I just came here to say hi?
Herbert feels dismissed.
Current empathy: {empathy}

* [Continue] -> Scene1_Player_Decision


=== Main_Convo_Response_2 ===
Herbert: Sure. 
Herbert tells you more detail about his sickness.
Current empathy: {empathy}

* [Continue] -> Scene1_Player_Decision


=== Main_Convo_Response_3 ===
Herbert: Me, too, buddy. Me, too.
Herbert didn't realize you were asking a question.
Current empathy: {empathy}

* [Continue] -> Scene1_Player_Decision


=== JVD_Convo ===
Player: I noticed your neck... there seems to be a distention here.
Herbert: You mean the weird lump over here?

* [Yes, would you mind if I take a closer look?]
    ~ empathy = empathy + 1
    ~ jvd_question_asked = true
    -> JVD_Convo_Response_1
* [Let me just take a closer look...]
    ~ empathy = empathy - 1
    ~ jvd_question_asked = true
    -> JVD_Convo_Response_2


=== JVD_Convo_Response_1 ===
Herbert: Sure thing.
Herbert agrees to let you examine him.
Current empathy: {empathy}

* [Continue] -> Scene2_Player_Decision


=== JVD_Convo_Response_2 ===
Herbert: Would it kill you to ask before touching me?
Herbert resents your decision to examine him without asking.
Current empathy: {empathy}

* [Continue] -> Scene2_Player_Decision


=== Medications_Convo ===
Player: I noticed on your chart you're taking some medications.
Herbert: And if I am?
~ questions_asked = questions_asked + 1
~ can_proceed_to_physical = (questions_asked > 1)

* [I just wanted to double check if you were taking them regularly.]
    ~ empathy = empathy + 1
    ~ medications_question_asked = true
    -> Meds_Convo_Response_1
* [You better be taking them regularly.]
    ~ empathy = empathy - 2
    ~ medications_question_asked = true
    -> Meds_Convo_Response_2
* [What's your favorite medication?]
    ~ empathy = empathy - 1
    ~ medications_question_asked = true
    -> Meds_Convo_Response_3


=== Meds_Convo_Response_1 ===
Herbert: ...Maybe... maybe not... fine, I admit it. I've been skipping them.
Herbert admits that he hasn't been taking his medications consistently.
Current empathy: {empathy}

* [Continue] -> Scene1_Player_Decision


=== Meds_Convo_Response_2 ===
Herbert: You're not the boss of me.
Herbert reacts defensively.
Current empathy: {empathy}

* [Continue] -> Scene1_Player_Decision


=== Meds_Convo_Response_3 ===
Herbert: What kind of question is that!?
Herbert is confused and frustrated.
Current empathy: {empathy}

* [Continue] -> Scene1_Player_Decision


=== Proceed_to_MCQ ===
Final Diagnosis

You have finished examining Herbert and gathering information.
Based on the information available, what is Herbert's condition?

* [A. Heart failure (HF)] -> Diagnosis_Complete
* [B. Not heart failure] -> Diagnosis_Incorrect
* [C. Herbert is dealing with lots of things] -> Diagnosis_Incorrect
* [D. Who is Herbert?] -> Diagnosis_Incorrect


=== Diagnosis_Complete ===
Congratulations! You identified the intended condition.
You have completed Herbert's examination.
Final empathy score: {empathy}

-> END


=== Diagnosis_Incorrect ===
That is not the intended diagnosis for this case.
Consider what you learned from Herbert's chart, physical observations, and conversation.
Final empathy score: {empathy}

-> END



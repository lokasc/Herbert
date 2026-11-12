using UnityEngine;
using Ink.Runtime;
using Ink.UnityIntegration;
using System.Collections.Generic;
using TMPro;
using UnityEngine.UI;

public class InkIntegration : MonoBehaviour
{
    // This keeps track of scores and all of that
    // I don't know if this is ideal but whateveeer
    [SerializeField] private GameManager gm;
    [SerializeField] private InkFile inkAsset;
    [SerializeField] private LayoutGroup layoutParent;

    [SerializeField] private Button herbertDialogueButton;
    [SerializeField] private Button choiceButton;

    [SerializeField] private Button nurseTextButton;

    [SerializeField] private TextMeshProUGUI nurseDialogueText;
    private Story _inkStory;
    private TextMeshProUGUI herbertDialogueText;
    
    private List<Button> currentChoices = new();

    public VariablesState InkVariables => _inkStory.variablesState;

    void Awake()
    {
        _inkStory = new Story(inkAsset.storyJson);
        herbertDialogueText = herbertDialogueButton.GetComponentInChildren<TextMeshProUGUI>();
        herbertDialogueButton.onClick.AddListener(()=>AdvanceStoryLine());
        nurseTextButton.onClick.AddListener(()=>AdvanceStoryLine());
    }

    void OnDisable()
    {  
        herbertDialogueButton.onClick.RemoveAllListeners();
        nurseTextButton.onClick.RemoveAllListeners();
    }

    void Start()
    {
        AdvanceStoryLine();
    }

    public void AdvanceStoryLine()
    {
        
        ClearChoiceObjects();
        HideNurse();

        // Add some script that checks if I'm jumping directly into a choice
        // Just to debug the "empty text box" of herbert when a knot starts with a choice

        if (_inkStory.canContinue)
        {
            string storyText = _inkStory.Continue();
            List<string> currentTags = _inkStory.currentTags;

            if (CheckForEmpathyTags(currentTags)) return;

            if (currentTags.Contains("nursenotification"))
            {
                DisplayNurse(storyText);
                return;
            }

            DisplayStoryText(storyText);
            return;
        }

        if (_inkStory.currentChoices.Count > 0)
        {
            for (int i = 0; i < _inkStory.currentChoices.Count; ++i)
            {
                Choice choice = _inkStory.currentChoices[i];
                CreateChoiceObject(choice);
            }
            return;

        }
        else
        {
            // Story has ended
            Debug.Log("Ink has ended");
            return;
        }

    }

    void DisplayNurse(string storyText)
    {
        nurseTextButton.gameObject.SetActive(true);
        nurseDialogueText.text = storyText;
        herbertDialogueButton.interactable = false;
        foreach (Button choiceButton in currentChoices)
        {
            choiceButton.interactable = false;
        }
    }

    void HideNurse()
    {
        nurseTextButton.gameObject.SetActive(false);
        herbertDialogueButton.interactable = true;
        foreach (Button choiceButton in currentChoices)
        {
            choiceButton.interactable = true;
        }
    }

    bool CheckForEmpathyTags(List<string> currentTags)
    {
        string empathyTag = currentTags.Find((myTag) => myTag.Contains("empathy"));
        if (empathyTag != null)
        {
            if (empathyTag == "empathyscore")
            {
                AdvanceStoryLine();
                return true;
            }
            string pathString = _inkStory.state.currentPathString;
            Debug.Log(pathString);
            int pathVisits = _inkStory.state.VisitCountAtPathString(pathString);
            Debug.Log("Path visits: " + pathVisits);

            int delta = int.Parse(empathyTag.Substring(7));

            gm.Empathy += delta;
        }
        return false;
    }

    void CreateChoiceObject(Choice choice)
    {
        GameObject co = Instantiate(choiceButton.gameObject, layoutParent.transform);

        Button coButton = co.GetComponent<Button>();
        coButton.onClick.AddListener(() => MakeChoice(choice));

        co.GetComponentInChildren<TextMeshProUGUI>().text = choice.text;

        currentChoices.Add(coButton);
    }

    void MakeChoice(Choice choice)
    {
        _inkStory.ChooseChoiceIndex(choice.index);
        AdvanceStoryLine();
    }

    void DisplayStoryText(string text)
    {
        herbertDialogueText.text = text;
    }

    void ClearChoiceObjects()
    {
        
        foreach (Button button in currentChoices)
        {
            button.onClick.RemoveAllListeners();
            Destroy(button.gameObject);
        }
        currentChoices.Clear();
    }


}

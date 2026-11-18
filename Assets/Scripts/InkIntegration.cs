using UnityEngine;
using Ink.Runtime;
using Ink.UnityIntegration;
using System.Collections.Generic;
using TMPro;
using UnityEngine.UI;
using UnityEngine.Rendering;
using Unity.Collections.Tests.CoreCLR.TestJobs;


public enum StoryState
{
    Chart,
    PatientInterview,
    Base,
}

public class InkIntegration : MonoBehaviour
{
    // This keeps track of scores and all of that
    // I don't know if this is ideal but whateveeer

    public Story InkStory => _inkStory;
    [SerializeField] private GameManager gm;
    [SerializeField] private InkFile inkAsset;

    [Header("General Buttons")]
    [SerializeField] private Button interviewEnterButton;
    [SerializeField] private Button chartEnterButton;

    [Header("Chart")]
    [SerializeField] private LayoutGroup chartLayoutParent;
    [SerializeField] private TextMeshProUGUI chartTopText;


    [Header("Interview")]
    [SerializeField] private LayoutGroup interviewLayoutParent;
    [SerializeField] private Button interviewDialogueButton;
    [SerializeField] private Button choiceButtonPrefab;

    [Header("Nurse Buttons and UI")]

    [SerializeField] private Button nurseTextButton;

    [SerializeField] private TextMeshProUGUI nurseDialogueText;
    private Story _inkStory;
    private TextMeshProUGUI herbertDialogueText;

    private List<Button> currentChoices = new();
    private StoryState _storyState = StoryState.Base;

    public VariablesState InkVariables => _inkStory.variablesState;



    void Awake()
    {
        _inkStory = new Story(inkAsset.storyJson);
        _inkStory.BindExternalFunction("switchState", (string state) =>
        {
            SwitchState(state);
        });

        herbertDialogueText = interviewDialogueButton.GetComponentInChildren<TextMeshProUGUI>();
        interviewDialogueButton.onClick.AddListener(() => AdvanceStoryLine());
        nurseTextButton.onClick.AddListener(() => AdvanceStoryLine());
        interviewEnterButton.onClick.AddListener(() => StartInterview());
        chartEnterButton.onClick.AddListener(() => StartChart());
    }

    void Start()
    {
        SwitchState("base");
    }

    void OnDisable()
    {
        interviewDialogueButton.onClick.RemoveAllListeners();
        nurseTextButton.onClick.RemoveAllListeners();
        interviewEnterButton.onClick.RemoveAllListeners();
        chartEnterButton.onClick.RemoveAllListeners();
    }

    void SwitchState(string stateName)
    {
        switch (stateName)
        {
            case "chart":
                HideGeneralMenuUI();
                chartLayoutParent.gameObject.SetActive(true);
                _storyState = StoryState.Chart;
                break;
            case "interview":
                HideGeneralMenuUI();
                interviewLayoutParent.gameObject.SetActive(true);
                _storyState = StoryState.PatientInterview;
                break;
            case "base":
                ShowGeneralMenuUI();
                _storyState = StoryState.Base;
                break;
        }
    }

    void HideGeneralMenuUI()
    {
        chartEnterButton.gameObject.SetActive(false);
        interviewEnterButton.gameObject.SetActive(false);
        chartLayoutParent.gameObject.SetActive(false);
    }

    void ShowGeneralMenuUI()
    {
        chartEnterButton.gameObject.SetActive(true);
        interviewEnterButton.gameObject.SetActive(true);
        chartLayoutParent.gameObject.SetActive(false);
        interviewLayoutParent.gameObject.SetActive(false);
    }

    public void AdvanceStoryLine()
    {

        ClearChoiceObjects();
        HideNurse();

        // Add some script that checks if I'm jumping directly into a choice
        // Just to debug the "empty text box" of herbert when a knot starts with a choice
        // Wire up the switching from dialogue to interview
        // For chart scene, there are two knots that I have to connect to
        // Look_at_Chart
        // Ask_Patient_Questions
        // Remove return to chart
        // Make sure the variables in the patient chart interact


        if (_inkStory.canContinue)
        {
            string storyText = _inkStory.Continue();
            List<string> currentTags = _inkStory.currentTags;

            if (CheckForEmpathyTags(currentTags)) return;

            if (string.IsNullOrWhiteSpace(storyText))
            {
                AdvanceStoryLine();
                return;
            }

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

    public void StartChart()
    {
        _inkStory.ChoosePathString("Look_at_Chart");
        AdvanceStoryLine();
    }

    public void StartInterview()
    {
        _inkStory.ChoosePathString("Ask_Patient_Questions");
        AdvanceStoryLine();
    }

    void DisplayNurse(string storyText)
    {
        nurseTextButton.gameObject.SetActive(true);
        nurseDialogueText.text = storyText;
        interviewDialogueButton.interactable = false;
        foreach (Button choiceButton in currentChoices)
        {
            choiceButton.interactable = false;
        }
    }

    void HideNurse()
    {
        nurseTextButton.gameObject.SetActive(false);
        interviewDialogueButton.interactable = true;
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
            // Can also update empathy here so that I don't update if you've already gone through that path (or I subtract)
            if (pathVisits < 1)
            {
                gm.Empathy = (int)_inkStory.variablesState["empathy"];
            }
        }
        return false;
    }

    void CreateChoiceObject(Choice choice)
    {
        LayoutGroup choiceParentGroup = _storyState == StoryState.Chart ? chartLayoutParent : interviewLayoutParent;
        GameObject co = Instantiate(choiceButtonPrefab.gameObject, choiceParentGroup.transform);

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
        if (_storyState == StoryState.PatientInterview)
        {
            herbertDialogueText.text = text;
        }
        if (_storyState == StoryState.Chart)
        {
            chartTopText.text = text;
            AdvanceStoryLine();
        }
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

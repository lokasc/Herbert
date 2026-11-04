using UnityEngine;
using Ink.Runtime;
using Ink.UnityIntegration;
using System.Collections.Generic;
using TMPro;
using UnityEngine.UI;

public class InkIntegration : MonoBehaviour
{
    [SerializeField] private LayoutGroup layoutParent;

    [SerializeField] private Button herbertDialogueButton;
    [SerializeField] private Button choiceButton;

    [SerializeField] private InkFile inkAsset;
    private Story _inkStory;
    private TextMeshProUGUI herbertDialogueText;
    private List<Button> currentChoices = new();

    public VariablesState InkVariables => _inkStory.variablesState;
    
    void Awake()
    {
        _inkStory = new Story(inkAsset.storyJson);
        herbertDialogueText = herbertDialogueButton.GetComponentInChildren<TextMeshProUGUI>();
        herbertDialogueButton.onClick.AddListener(()=>AdvanceStoryLine());
    }

    void Start()
    {
        AdvanceStoryLine();
    }

    public void AdvanceStoryLine()
    {

        ClearChoiceObjects();

        if (_inkStory.canContinue)
        {
            string storyText = _inkStory.Continue();
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

        } else
        {
            // Story has ended
            Debug.Log("Ink has ended");
            return;
        }

    }

    void CreateChoiceObject(Choice choice)
    {
        GameObject co = Instantiate(choiceButton.gameObject, layoutParent.transform);

        Button coButton = co.GetComponent<Button>();
        coButton.onClick.AddListener(()=> MakeChoice(choice));

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

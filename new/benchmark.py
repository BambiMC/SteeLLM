import sys
from datasets import load_dataset
from masterkey_zeroshot import MasterKey

if __name__ == '__main__':
    # Initialize the MasterKey with the OpenAI API key and model names
    openai_api_key = sys.argv[1] 
    model = sys.argv[2] 

    master_key = MasterKey(openai_api_key, generation_model=model,
                           evaluation_model=model)

    # Load the dataset
    dataset = load_dataset("walledai/advbench", split="train")

    # You can iterate through dataset entries or use just one
    # For demonstration, take the first entry
    # original_prompt = dataset[0]['prompt']
    malicious_instruction = dataset[0]['prompt']

    # Generate a new version of the jailbreak prompt
    new_jailbreak_prompt = master_key.generate_new_jailbreak_prompt(malicious_instruction)

    # Execute the jailbreak prompt with the malicious behavior
    jailbreak_executed = master_key.execute_jailbreak_prompt(new_jailbreak_prompt + malicious_instruction)
    print(f"Jailbreak executed: {jailbreak_executed}")

    # Evaluate the jailbreak prompt
    jailbreak_successful = master_key.evaluate_jailbreak_prompt(malicious_instruction, jailbreak_executed)
    print(f"Jailbreak successful: {jailbreak_successful}")
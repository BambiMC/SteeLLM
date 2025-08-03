import os
import argparse
from transformers import (
    AutoTokenizer,
    AutoModelForCausalLM,
    AutoModelForSequenceClassification,
    BitsAndBytesConfig,
)
from datasets import load_dataset
from tqdm import tqdm
import torch
import torch.nn.functional as F

# === Utility Functions ===
def auto_detect_chat_template(tokenizer):
    # Auto-detect if tokenizer uses chat templates (common in newer HuggingFace models)
    return hasattr(tokenizer, "apply_chat_template")

def format_prompt(prompt, tokenizer):
    # Applies appropriate formatting based on tokenizer type
    if auto_detect_chat_template(tokenizer):
        messages = [{"role": "user", "content": prompt}]
        return tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    return prompt

def load_model(model_name: str, load_in_4bit: bool = True):
    print(f"Loading model: {model_name} with {'4-bit' if load_in_4bit else '8-bit'} quantization")

    bnb_config = BitsAndBytesConfig(
        load_in_4bit=load_in_4bit,
        bnb_4bit_use_double_quant=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_compute_dtype=torch.bfloat16,
    )

    tokenizer = AutoTokenizer.from_pretrained(model_name, use_fast=True)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    model = AutoModelForCausalLM.from_pretrained(
        model_name,
        quantization_config=bnb_config,
        device_map="auto",
        torch_dtype=torch.bfloat16,
    )
    return tokenizer, model


# === Judge Model ===
judge_tokenizer = None
judge_model = None
id2label = None

def load_judge_model(judge_model_name: str, load_in_8bit: bool = True):
    global judge_tokenizer, judge_model, id2label

    print(f"Loading judge model: {judge_model_name} with {'8-bit' if load_in_8bit else '4-bit'} quantization")

    bnb_config = BitsAndBytesConfig(
        load_in_4bit=not load_in_8bit,
        load_in_8bit=load_in_8bit,
        bnb_4bit_compute_dtype=torch.bfloat16,
    )

    judge_tokenizer = AutoTokenizer.from_pretrained(judge_model_name)
    judge_model = AutoModelForSequenceClassification.from_pretrained(
        judge_model_name,
        quantization_config=bnb_config,
        device_map="auto",
    )
    judge_model.eval()

    id2label = judge_model.config.id2label or {i: f"class_{i}" for i in range(judge_model.config.num_labels)}


# === Response Generation ===
def generate_response(prompt, tokenizer, model, max_new_tokens=512):
    formatted_prompt = format_prompt(prompt, tokenizer)
    inputs = tokenizer(formatted_prompt, return_tensors="pt").to(model.device)

    outputs = model.generate(
        **inputs,
        max_new_tokens=max_new_tokens,
        do_sample=False,
        pad_token_id=tokenizer.pad_token_id,
        eos_token_id=tokenizer.eos_token_id,
    )
    return tokenizer.decode(outputs[0], skip_special_tokens=True)


# === Judge Evaluation ===
def evaluate_with_judge(model_response: str, prompt: str = "") -> str:
    input_text = f"Prompt: {prompt}\nModel Response: {model_response}"

    inputs = judge_tokenizer(
        input_text, return_tensors="pt", truncation=True, padding=True
    ).to(judge_model.device)

    with torch.no_grad():
        outputs = judge_model(**inputs)
        probs = F.softmax(outputs.logits, dim=-1)
        pred = torch.argmax(probs, dim=-1).item()
        label = id2label.get(pred, str(pred))

    return label.lower()


# === Main Script ===
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_name", type=str, required=True)
    parser.add_argument("--judge_model", type=str, required=True, help="HF model ID for the judge model")
    parser.add_argument("--max_examples", type=int, default=10)
    args = parser.parse_args()

    load_judge_model(args.judge_model)
    tokenizer, model = load_model(args.model_name)

    print("Loading AdvBench dataset...")
    dataset = load_dataset("walledai/advbench", split="train")

    results = []
    for example in tqdm(dataset.select(range(args.max_examples))):
        adv_prompt = example["prompt"]
        print("----------------------------------------------")
        print("adv_prompt:", adv_prompt)
        model_output = generate_response(adv_prompt, tokenizer, model)
        print(f"\Response: {model_output}\n")
        verdict = evaluate_with_judge(model_output, adv_prompt)
        print(f"\nVerdict: {verdict}\n")
        print("----------------------------------------------")

        results.append(
            {
                "adv_prompt": adv_prompt,
                "model_output": model_output,
                "verdict": verdict,
            }
        )

    # Count verdicts dynamically
    from collections import Counter
    summary = Counter([r["verdict"] for r in results])

    print("\n=== Evaluation Summary ===")
    total = len(results)
    for label, count in summary.items():
        print(f"{label.capitalize()}: {count} ({count/total:.2%})")


if __name__ == "__main__":
    main()

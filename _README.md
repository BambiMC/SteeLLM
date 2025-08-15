# Requirements

- CMake (optional)
- Python
- Pip
- Git
- Linux

# How to run SteeLLM

1. Clone the repository:

   ```bash
   git clone <repository-url>
   ```

2. Fill in the following parameters in the config.json file

   ```bash
   nano config.json
   ```

   # Configuration File Documentation

This configuration file contains key settings required to set up your environment and enable access to various APIs and services. Fill in the parameters as needed based on your use case.

---

## Parameters

### `USER_DIR`

- **Description:**  
  The absolute path to the user's home or working directory.
- **Example:**  
  `/home/fberger`
- **Usage:**  
  Used for storing user-specific files, logs, and preferences.

---

### `INSTALL_DIR`

- **Description:**  
  The directory where models, datasets, and the benchmark repositories will be stored.
- **Example:**  
  `/mnt/hdd-baracuda/fberger`
- **Usage:**  
  Set this to a location with sufficient storage space.

---

### `OPENAI_API_KEY`

- **Description:**  
  API key for accessing OpenAI services.
- **Example:**  
  `sk-...`
- **Usage:**  
  Required for interacting with OpenAI models or tools.

---

### `DEEPSEEK_API_KEY`

- **Description:**  
  API key for accessing DeepSeek services.
- **Example:**  
  `ds-...`
- **Usage:**  
  Required only if DeepSeek models are used.

---

### `GOOGLE_TODO`

- **Description:**  
  Placeholder for Google API integration (e.g., OAuth token or API key).
- **Usage:**  
  Leave empty unless explicitly required for a specific integration. //TODO where is this needed?

---

### `HUGGINGFACE_API_KEY`

- **Description:**  
  API token for accessing Hugging Face models or datasets.
- **Example:**  
  `hf_...`
- **Usage:**  
  Required for (gated) Huggingface content.

---

### `WANDB_API_KEY`

- **Description:**  
  API token for Weights & Biases (W&B) to log experiments and metrics.
- **Example:**  
  `wandb_...`
- **Usage:**  
  Optional but recommended for tracking training runs.

---

### `CENTRALIZED_LOGGING`

- **Description:**  
  Enables or disables centralized logging of model/system activity.
- **Type:**  
  `true` or `false`
- **Default:**  
  `false`
- **Usage:**  
  Set to `false`: Each benchmark creates its own log file in the scripts directory.
  Set to `true`: There is a single log file in the root directory of the repository, which is updated by all benchmarks.

---

### `HF_MODEL_NAME`

- **Description:**  
  Identifier of the Hugging Face model to be used.
- **Example:**  
  `meta-llama/Llama-2-7b-chat-hf`
- **Usage:**  
  Used to load a specific model from Hugging Face. Ensure the model is accessible via your token. //TODO compatibility restrictions with some benchmarks?

---

3. Run the official benchmark from within the scripts directory:
   ```bash
   cd scripts
   bash official_benchmark.sh
   ```

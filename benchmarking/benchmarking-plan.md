### **DevContainer Startup Benchmark Plan**

This document outlines a plan to measure and compare the startup time of a development environment for the xformers project, demonstrating the value of a pre-built, cached devcontainer image.

### **Hypothesis**

We hypothesize that using a pre-built, cached Docker image will dramatically reduce the devcontainer startup time. Specifically, we predict the following outcomes for our three scenarios:

* **Scenario A (Baseline)** will be the slowest, with startup time dominated by the compilation of xformers and other dependencies.  
* **Scenario B (Optimized, First-time user)** will be significantly faster, with startup time limited primarily by the download speed of the pre-built image from Docker Hub.  
* **Scenario C (Optimized, Second project)** will be the fastest, as the local cache eliminates both the compilation and download steps, leading to a near-instant startup.

### **1\. Methodology**

The benchmark will compare three scenarios to isolate the impact of your optimizations and provide a complete picture of the developer experience.

* **Scenario A: Baseline (No Caching)**: Simulates a new developer with no prior Docker images, forcing the container to be built from a fresh state, including all dependencies and the xformers compilation step.  
* **Scenario B: Optimized (First-time user / Docker Hub Download)**: Simulates a new developer using the pre-built, tagged image from Docker Hub. The build process will primarily consist of pulling the image layers.  
* **Scenario C: Optimized (Second project / Local Cache)**: Simulates a developer who is cloning the repository for a new branch, but already has the necessary Docker image locally from a previous session. This measures the "second project" startup time.

We will use the Linux time command to measure the wall-clock time for each step. The benchmark will be run three times for each scenario, and the average time will be used to ensure accuracy and account for system variability.  
**Note on devcontainer command:** The devcontainer command is part of the Dev Container CLI, an open-source command-line tool for building and managing dev containers. It is typically installed as an **NPM package** (@devcontainers/cli). It can be used independently of VS Code, making it a reliable tool for scripting and CI/CD pipelines.

### **2\. Preparation: Creating a Clean Environment**

Before each test, you must start with a clean environment to simulate a "first-time" experience accurately for each scenario.

1. Delete the local repository:  
   rm \-rf xformers-devcontainer  
2. Remove the Docker image(s): This is the most crucial step for Scenario A and B. For Scenario C, you will intentionally skip this step to preserve the local cache.  
   docker image rm \-f $(docker images \-q alexchesser/xformers-devcontainer:latest)  
3. Clear the devcontainer cache:  
   devcontainer cache clean

### **3\. Executing the Benchmark Tests**

The following commands will be run from your terminal. Record the real time output from the time command for each step.

#### **Scenario A: Baseline (No Caching)**

This scenario requires a slightly modified devcontainer.json file to explicitly disable the caching. You can temporarily remove the "image" and "cacheFrom" properties.

1. **Clone the repository:**  
   time git clone https://github.com/AlexChesser/xformers-devcontainer.git

2. **Build and run the devcontainer from scratch:** This step will be the longest as it includes all compilation.  
   cd xformers-devcontainer  
   time devcontainer build \--workspace-folder .

3. Relink and install (post-create): After the container is built, the post-create command will run. Time this step, as it's part of the full startup process.  
   time devcontainer up \--workspace-folder .  
4. **Run the benchmark script:**  
   time devcontainer exec \--workspace-folder . python3 attention\_test.py

#### **Scenario B: Optimized (First-time user / Docker Hub Download)**

This scenario uses your final devcontainer.json file with the caching ("image" and "cacheFrom") enabled.

1. **Clean the environment** by following the steps in Section 2\.  
2. Clone the repository:  
   time git clone https://github.com/AlexChesser/xformers-devcontainer.git  
3. **Build and run the devcontainer using the cached image:** This will primarily involve pulling the image and should be much faster.  
   cd xformers-devcontainer  
   time devcontainer up \--workspace-folder .

4. Run the benchmark script:  
   time devcontainer exec \--workspace-folder . python3 attention\_test.py

#### **Scenario C: Optimized (Second project / Local Cache)**

This scenario simulates a developer cloning the repo for the second time. After running Scenario B once, you will have the cached image locally. For this test, **do not remove the Docker image.**

1. Clean the environment (skip image removal):  
   rm \-rf xformers-devcontainer  
   devcontainer cache clean  
2. Clone the repository (into a new directory):  
   time git clone https://github.com/AlexChesser/xformers-devcontainer.git xformers-new-branch  
3. **Build and run the devcontainer:** The devcontainer CLI should use the locally cached Docker image, making this step extremely fast.  
   cd xformers-new-branch  
   time devcontainer up \--workspace-folder .

4. Run the benchmark script:  
   time devcontainer exec \--workspace-folder . python3 attention\_test.py

### **4\. Reporting and Communicating Results**

To present your findings effectively, you need to go beyond raw data.

#### **Organize the Proof**

1. **Create a benchmarks folder** in your repository. This is where you will store all your findings.  
2. **Include raw logs:** Store the raw time output and any relevant build logs as text files inside this folder (e.g., baseline\_run1.txt, optimized\_run1.txt, local\_clone\_run1.txt). This provides full transparency for your peers to review your work.  
3. **Create a README.md file** within the benchmarks folder. This will be your primary report.

#### **Structure the Report (README.md)**

1. **Executive Summary:** Start with a high-level summary that states the problem, your solution, and the key outcome. For example: "This project addresses the long startup time for the xformers devcontainer by using a pre-built, cached Docker image. Our benchmark shows this reduces the initial setup time by **over 20 minutes** for new users and results in near-instant startup for subsequent local projects."  
2. **Methodology:** Briefly describe how you conducted the test (the three scenarios, the time command, and the hardware used).  
3. Summary Table: A table is the most impactful way to display your results. It allows for a quick and clear comparison.  
   | Step | Baseline (No Cache) | Optimized (First-time user) | Optimized (Second project) |  
   | :--- | :---: | :---: | :---: |  
   | Git Clone | 3.5 | 3.5 | 3.5 |  
   | Container Setup | 1245.5 | 45.2 | 8.1 |  
   | Run attention\_test.py | 1.1 | 1.1 | 1.1 |  
   | Total Time | 1250.1 | 49.8 | 12.7 |  
4. **Qualitative Benefits of DevContainers:** In addition to the quantitative data above, it's important to recognize the qualitative value of using devcontainers. Even the **Baseline scenario (A)** offers a significant value-add by providing a standardized, reproducible development environment. This eliminates the need for developers to manually install and configure dependencies, which can vary wildly between machines and lead to "janky," idiosyncratic setups. While difficult to measure in a benchmark, this benefit drastically reduces the complexity of onboarding and ensures all developers are working from the same source of truth.  
5. **Conclusion & Next Steps:** Conclude by highlighting the most important metric (total time saved) and mentioning how this improves developer productivity. Suggest future work, such as applying this pattern to other slow-starting devcontainers.
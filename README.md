### [The Welfare Effects of Encouraging Rural-Urban Migration](http://www.waugheconomics.com/uploads/2/2/5/6/22563786/LMW.pdf)

<p align="center">
<img src="migration_rates.png">
</p>

---
This repository contains code to reproduce results from the paper ["The Welfare Effects of Encouraging Rural-Urban Migration"](http://www.waugheconomics.com/uploads/2/2/5/6/22563786/LMW.pdf). It also includes replication files (empirical and quantitative results) for the paper ["Underinvestment in a Profitable
Technology: The Case of Seasonal Migration in Bangladesh"](https://onlinelibrary.wiley.com/doi/abs/10.3982/ECTA10489) that were downloaded from Econometrica's code repository and obtained from the authors. I will provide support for the former, not for the later.

**Complete explanations of the repository are currently under construction.**

**Software Requirements:** Outside of plotting (and the data analysis of the field experiment) all of this code is in MATLAB and requires the Parallel Computing Toolbox (for computation of the model) and the Global Optimization Toolbox (for calibration).

With access to 12 cores (Xeon E5-2690 processors) the model (with a dense productivity and asset grid) is solved in about 100 seconds. Simple modifications to speed up computation are to reduce the productivity grid(s), without loosing much in terms of equilibrium outcomes.

#### Basic Calls
---
**Compute Model:** The most basic call starts inside the [``\revision_code\calibration``](https://github.com/mwaugh0328/welfare_migration/tree/master/revision_code/calibration) folder. From there to generate outcomes from the model and the partial equilibrium welfare numbers is here:

```
>> load('calibration_final.mat')

>> analyze_outcomes_prefshock(exp(new_val), 1)
```
Then it should compute everything and then spit out the moments. In ``analyze_outcomes_prefshock.m`` you can see each step (i) value function iteration (ii) simulation to construct stationary distribution (iii) implementation of experiment and (iv) collect results. The results should mimic (or come very close) to those in Table 2, 6, and 8 in the January 2020 version of the paper.

The ``calibration_final.mat`` contains the final, calibrated parameter values reported in the paper as the array ``new_val``. They are in log units, so to convert to levels take ``exp``. The mapping from the values to their description is given by the structure ``labels`` which, for example,
```
>> labels(3)

ans = "urban TFP"
```
tells us that in the third position of ``new_val`` is urban TFP.

---
**Compute GE Counterfactual:** Start inside the [``\revision_code\ge_counterfactual``](https://github.com/mwaugh0328/welfare_migration/tree/master/revision_code/ge_counterfactual) folder. Then call
```
>> eq_compute
```
which will do everything: Infer wages-per-efficiency units from the calibrated model, compute welfare holding wages fixed, compute welfare with wages changing in equilibrium. This should replicate the results in Table 8. Notes describing more detail about the GE computation are [here](https://github.com/mwaugh0328/welfare_migration/blob/master/notes_ge_version/notes_GE_analysis.pdf)

---

**Calibrate the Model:** The calibration routine is implemented by starting inside the [``\revision_code\calibration``](https://github.com/mwaugh0328/welfare_migration/tree/master/revision_code/calibration)
```
>> calibrate_wrap_tight
```
And then within it you can see how it works. It calls ``compute_outcomes_prefshock.m`` which is similar to the ``analyze...`` file above but is optimized for the calibration routine.  The key to get this thing to fit was using the ``ga`` solver which is essentially a search of the entire parameter space in a smart way. The current settins have a tight bounds on the parameter space. The original calibration routine had very loose bounds. Alternative approaches with different minimizers (``patternsearch`` ``fminsearch`` (with and without random start) and some ``NAG`` routines) are in the ``graveyard`` folder.

---

#### Complete Contents

**under construction**

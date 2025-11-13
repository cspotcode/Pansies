Plan how to implement this change, then write the plan to plan.md:

Pansies calls Add-Type conditionally on load. This greatly increases startup time. To fix this, we should move the conditionally-loaded type into a second DLL which will be precompiled. At module load time, pansies will conditionally load this second DLL.

Pansies already builds a single DLL. This change is to additionally build a second DLL
Refactor dotnet configuration to build second DLL
Implement .cs for second DLL
Refactor build script to build both DLLs at the same time

---

concerns:
How will the new

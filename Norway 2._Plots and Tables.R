####################################################################################################
# For:          Norway
# Paper:        Injury-Mental Health connections
# Programmer:	 Renate Houts
# File:         02_HR_PlotsTables_Mar2024.R
# Date:	       26/03/2024
#
# Purpose: 
#     Create Plots/Tables for MH --> Injury Paper
#
# ##################################################################################################

library(tidyverse)
library(plotly)
library(haven)

MH_order <- c("Any Mental Health Condition",
              "Acute stress reaction",
              "ADHD",
              "Anxiety",
              "Chronic fatigue",
              "Depression",
              "Developmental delay",
              "Personality disorder",
              "Phobia/Compulsive disorder",
              "Psychosis",
              "PTSD",
              "Sexual concern",
              "Sleep disturbance",
              "Substance abuse",
              "NOS"
               )

# eAppendix 4
prevalence <- read_csv('M:/p1074-renateh/2023_MHInjuries/MHInj_eAppendix4_Prev_05Apr2024.csv') %>%
               filter(CumFrequency == 2753646) %>%
               mutate(Injury = ifelse(Table == "Table any_A", "A: General & Unspecified",
                               ifelse(Table == "Table any_D", "D: Digestive",
                               ifelse(Table == "Table any_F", "F: Eye",
                               ifelse(Table == "Table any_H", "H: Ear",
                               ifelse(Table == "Table any_L", "L: Musculoskeletal",
                               ifelse(Table == "Table any_N", "N: Neurological",
                               ifelse(Table == "Table any_S", "S: Skin",
                               ifelse(Table == "Table any_O", "Other, B, R, U, W, X/Y",
                               ifelse(Table == "Table any_inj", "Any Injury", NA)))))))))) %>%
               mutate(MH = ifelse(Table == "Table any_dep",  "Depression",
                           ifelse(Table == "Table any_str",  "Acute stress reaction",
                           ifelse(Table == "Table any_slp",  "Sleep disturbance",
                           ifelse(Table == "Table any_NOS",  "Psychological condition, NOS",
                           ifelse(Table == "Table any_anx",  "Anxiety",
                           ifelse(Table == "Table any_sub",  "Substance abuse",
                           ifelse(Table == "Table any_phb",  "Phobia/Compulsive disorder",
                           ifelse(Table == "Table any_psy",  "Psychosis",
                           ifelse(Table == "Table any_sex",  "Sexual concern",
                           ifelse(Table == "Table any_adhd", "ADHD",
                           ifelse(Table == "Table any_ptsd", "PTSD",
                           ifelse(Table == "Table any_per",  "Personality disorder",
                           ifelse(Table == "Table any_dev",  "Developmental delay/Learning problem",
                           ifelse(Table == "Table any_crf",  "Neuresthenia/surmenage (chronic fatigue)", 
                           ifelse(Table == "Table any_MH",   "Any Mental Health Condition", NA)))))))))))))))) 
Inj_prev <- prevalence %>%
               filter(!is.na(Injury)) %>%
               arrange(-Percent) %>%
               mutate(Condition = Injury) %>%
               select(Condition, Frequency, Percent)
MH_prev  <- prevalence %>%
               filter(!is.na(MH)) %>%
               arrange(-Percent) %>%
               mutate(Condition = MH) %>%
               select(Condition, Frequency, Percent)

Prevalences <- bind_rows(MH_prev, Inj_prev)
rm(prevalence, MH_prev, Inj_prev)

write_csv(Prevalences, 
          'M:/p1074-renateh/2023_MHInjuries/MHInj_eAppendix4_Prev_05Apr2024_Pretty.csv')

#eAppendix 13
HRs_ByGrps_C <- read_csv('M:/p1074-renateh/2023_MHInjuries/MHInj_eAppendix13_GrpHRs_03Apr2024_CleanMH.csv') %>%
                  mutate(HR_CL = paste0(format(round(HazardRatio, 2), nsmall = 2), " [", 
                                        format(round(HRLowerCL, 2),   nsmall = 2), ", ", 
                                        format(round(HRUpperCL, 2),   nsmall = 2), "]")) %>%
                  relocate(Sex,         .before = Parameter) %>%
                  relocate(Age,         .after  = Sex) %>%
                  relocate(HazardRatio, .after  = Age) %>%
                  relocate(HRLowerCL,   .after  = HazardRatio) %>%
                  relocate(HRUpperCL,   .after  = HRLowerCL) %>%
                  relocate(HR_CL,       .after  = Age) %>%
                  select(-Parameter, -DF, -MHvar, -PHvar)
write_csv(HRs_ByGrps_C, 
          'M:/p1074-renateh/2023_MHInjuries/MHInj_eAppendix13_GrpHRs_03Apr2024_CleanMH_Pretty.csv')

# Figure 3 estimates
risk <- read_csv('M:/p1074-renateh/2023_MHInjuries/MHInj_Figure3_Risks_05Apr2024.csv') %>%
         pivot_wider(names_from = Row, values_from = c(Risk, StdErr, LowerCL, UpperCL)) %>%
         mutate(Risk_Mental = paste0(format(round(Risk_MH*100, 2),    nsmall = 2), "% [", 
                                     format(round(LowerCL_MH*100, 2), nsmall = 2), "%, ", 
                                     format(round(UpperCL_MH*100, 2), nsmall = 2), "%]"),
                Risk_NoMental = paste0(format(round(`Risk_No MH`*100, 2),    nsmall = 2), "% [", 
                                       format(round(`LowerCL_No MH`*100, 2), nsmall = 2), "%, ", 
                                       format(round(`UpperCL_No MH`*100, 2), nsmall = 2), "%]"),
                Risk_Diff = paste0(format(round(Risk_Difference*-100, 2),    nsmall = 2), "% [", 
                                   format(round(LowerCL_Difference*-100, 2), nsmall = 2), "%, ", 
                                   format(round(UpperCL_Difference*-100, 2), nsmall = 2), "%]")) %>%
         mutate(MH_Condition = 
                   ifelse(Table == "Table prev_dep * injury",  "Depression",
                   ifelse(Table == "Table prev_str * injury",  "Acute stress reaction",
                   ifelse(Table == "Table prev_slp * injury",  "Sleep disturbance",
                   ifelse(Table == "Table prev_NOS * injury",  "Psychological condition, NOS",
                   ifelse(Table == "Table prev_anx * injury",  "Anxiety",
                   ifelse(Table == "Table prev_sub * injury",  "Substance abuse",
                   ifelse(Table == "Table prev_phb * injury",  "Phobia/Compulsive disorder",
                   ifelse(Table == "Table prev_psy * injury",  "Psychosis",
                   ifelse(Table == "Table prev_sex * injury",  "Sexual concern",
                   ifelse(Table == "Table prev_ADHD * injury", "ADHD",
                   ifelse(Table == "Table prev_ptsd * injury", "PTSD",
                   ifelse(Table == "Table prev_per * injury",  "Personality disorder",
                   ifelse(Table == "Table prev_dev * injury",  "Developmental delay/Learning problem",
                   ifelse(Table == "Table prev_crf * injury",  "Chronic fatigue", 
                   ifelse(Table == "Table prev_MH * injury",   "Any Mental Health Condition", NA)))))))))))))))) %>%
         select(MH_Condition, Risk_Mental, Risk_NoMental, Risk_Diff, Risk_MH, LowerCL_MH, UpperCL_MH, 
                `Risk_No MH`, `LowerCL_No MH`, `UpperCL_No MH`, Risk_Difference, LowerCL_Difference, UpperCL_Difference)

write_csv(risk, 
          'M:/p1074-renateh/2023_MHInjuries/MHInj_Figure3_Risks_05Apr2024_Pretty.csv')

# Figure 4 estimates
HRs_C <- read_csv('M:/p1074-renateh/2023_MHInjuries/MHInj_Figure4_HRs_03Apr2024_CleanMH.csv') %>%
                  filter(Parameter == "tvmh") %>%
                  mutate(HR_CL = paste0(format(round(HazardRatio, 2), nsmall = 2), " [", 
                                        format(round(HRLowerCL, 2),   nsmall = 2), ", ", 
                                        format(round(HRUpperCL, 2),   nsmall = 2), "]")) %>%
                  mutate(PHvar = ifelse(PHvar == 'Injury',             'Any Body System', PHvar),
                         PHvar = ifelse(PHvar == 'A: General',         'General & Unspecified', PHvar),
                         PHvar = ifelse(PHvar == 'D: Digestive',       'Digestive', PHvar),
                         PHvar = ifelse(PHvar == 'F: Eye',             'Eye', PHvar),
                         PHvar = ifelse(PHvar == 'H: Ear',             'Ear', PHvar),
                         PHvar = ifelse(PHvar == 'L: Musculoskeletal', 'Musculoskeletal', PHvar),
                         PHvar = ifelse(PHvar == 'N: Neurological',    'Neurological', PHvar),
                         PHvar = ifelse(PHvar == 'S: Skin',            'Skin', PHvar),
                      
                         MHvar = ifelse(MHvar == "MH",                   "Any Mental Health Condition", MHvar),
                         MHvar = ifelse(MHvar == "Acute Stress",         "Acute stress reaction", MHvar),
                         MHvar = ifelse(MHvar == "Developmental Delay",  "Developmental delay", MHvar),
                         MHvar = ifelse(MHvar == "Phobia",               "Phobia/Compulsive disorder", MHvar),
                         MHvar = ifelse(MHvar == "Sexual Concern",       "Sexual concern", MHvar),
                         MHvar = ifelse(MHvar == "Sleep Disturbance",    "Sleep disturbance", MHvar),
                         MHvar = ifelse(MHvar == "Substance Abuse",      "Substance abuse", MHvar),
                         MHvar = ifelse(MHvar == "Personality Disorder", "Personality disorder", MHvar),
                         MHvar = ifelse(MHvar == "Psychological symptom/disorder, NOS", "NOS", MHvar),
                         MHvar = ifelse(MHvar == "Psychological sympto", "NOS", MHvar),
                         MHvar = ifelse(MHvar == "Chronic fatigue",      "Chronic fatigue", MHvar)
                         ) %>%
                  relocate(HR_CL,       .before = Parameter) %>%
                  relocate(HazardRatio, .after  = HR_CL) %>%
                  relocate(HRLowerCL,   .after  = HazardRatio) %>%
                  relocate(HRUpperCL,   .after  = HRLowerCL) %>%
                  relocate(PHvar,       .before = HR_CL) %>%
                  relocate(MHvar,       .before = PHvar) %>%
                  select(-Parameter, -DF)

HR_Table_C <- HRs_C %>%
               select(MHvar, PHvar, HR_CL) %>%
               pivot_wider(names_from = PHvar, values_from = HR_CL) %>%
               arrange(factor(MHvar, levels = MH_order))

write_csv(HR_Table_C, 
          'M:/p1074-renateh/2023_MHInjuries/MHInj_Figure4_HRs_03Apr2024_CleanMH_Pretty.csv')

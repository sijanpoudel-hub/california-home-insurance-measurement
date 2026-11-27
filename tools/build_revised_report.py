"""Build the revised manuscript and a separate complete robustness supplement.
All numerical prose and tables are populated from completed outputs.
"""
from pathlib import Path
import html,json,os,re
import pandas as pd
from docx import Document
from docx.shared import Inches,Pt
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
font_path=Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
if font_path.exists():
    pdfmetrics.registerFont(TTFont("DejaVuSans",str(font_path)))
    pdfmetrics.registerFont(TTFont("DejaVuSans-Bold",str(font_path.with_name("DejaVuSans-Bold.ttf"))))
    pdfmetrics.registerFontFamily("DejaVuSans",normal="DejaVuSans",bold="DejaVuSans-Bold",italic="DejaVuSans",boldItalic="DejaVuSans-Bold")
from reportlab.lib.styles import getSampleStyleSheet,ParagraphStyle
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate,Paragraph,Spacer,Table,TableStyle,PageBreak
ROOT=Path(__file__).resolve().parents[1]; O=ROOT/"outputs"; D=ROOT/"deliverables";D.mkdir(exist_ok=True)
def read(name):return pd.read_csv(O/name)
grid=read("extended_definition_grid.csv")
den=read("extended_denominator_comparisons.csv")
select=read("extended_denominator_selection.csv")
rev=read("extended_release_reconciliation.csv")
loc=read("extended_leave_one_county_out.csv")
orig=read("extension_matched_input.csv")
orig=orig.rename(columns={"new":"N","renewed":"R","insurer_nonrenewed":"I","insured_nonrenewed":"U","recorded_count_total":"T"})
orig["visible"]=orig.federal_usable.astype(str).str.lower().eq("true")
base=grid[(grid.minimum_T==100)&(grid.top_fraction==.1)].copy()
other=grid[~((grid.minimum_T==100)&(grid.top_fraction==.1))]
newden=den[(den.comparison=="Insurer versus combined")&(den.denominator=="D")&(den.top_fraction==.1)]
dchange=den[(den.comparison=="Denominator change")&(den.top_fraction==.1)]
om=loc[loc.excluded_county!="NONE"]
def fmt(x,digits=3):
    if pd.isna(x):return ""
    if isinstance(x,(int,)) or (isinstance(x,float) and x.is_integer()):return f"{int(x):,}"
    if isinstance(x,(int,float)):return f"{x:,.{digits}f}"
    return str(x)
def span(s,dec=2):return f"{s.min():.{dec}f}–{s.max():.{dec}f}"
B=[]
def p(text):B.append(("p",text))
def h(text):B.append(("h",text))
def table(title,df,cols):
    B.append(("table",(title,[label for key,label in cols],
                      [[fmt(r[key],6 if "pp" in key else 3) for key,label in cols] for _,r in df.iterrows()])))
title="Coverage and Definition Sensitivity in California Home Insurance Measures"
p("Sijan Poudel | J. Mack Robinson College of Business, Georgia State University, Atlanta, Georgia, USA")
p("Revised after additional exploratory robustness checks. This version supersedes the earlier numerical interpretation only where expressly discussed below.")
h("Abstract")
p(f"Public insurance measures depend on geographic coverage, event definitions and normalization. Using 8,503 California ZIP-year records for 2018–2021, this study compares state descriptive shares before and after restriction to published federal nonrenewal data. Federal values cover 73.13% of records but 99.843% of the pooled constructed normalizing total. Geographic restriction changes annual statewide insurer-initiated shares by approximately −0.0016 to −0.0051 percentage points. Under the primary minimum of 100 recorded counts and annual top-decile rule, 2.55%–5.10% of hotspots lack federal values; none are omitted with a 200-count minimum. Insurer-only and combined definitions retain {span(base.retention_pct)}% of insurer-defined hotspots in common. Additional checks vary selection rules, use new plus renewed policies as an alternative descriptive normalizer, leave out each county, and reconcile overlapping releases. Across the full definition grid, retention ranges from {span(grid.retention_pct)}%. The alternative normalizer yields primary-rule retention of {span(newden.retention_pct)}%. Results concern released counts and expressly defined indices, rather than household insurance-loss probabilities.")
p("Keywords: homeowners insurance; nonrenewals; cancellations; geographic coverage; measurement; California")
h("1. Introduction")
p("Public insurance data help researchers describe insurance-market stress and identify locations receiving policy attention. The resulting conclusions depend on which places are observed, which events are counted, and which denominator is used. A dataset can omit many geographic labels while representing most recorded activity; an event definition can also change local rankings even when the underlying sample is fixed.")
p("This study asks how published federal availability and alternative California event definitions change descriptive measures during 2018–2021. It holds the California outcome fixed when restricting geographic coverage. It separately compares insurer-initiated and combined insurer/policyholder termination categories. A third exercise checks how results respond to a different descriptive denominator.")
p("The contribution is an empirical measurement audit with reproducible comparisons. The study does not claim that insurance-data limitations are newly discovered. Its results do not validate federal rate levels against an identical state target, establish a causal climate effect, or measure household uninsurance.")
h("2. Related research")
p("Liao et al. (2022) examine California initiation categories alongside wildfire risk and social vulnerability and distinguish postal ZIP codes from Census ZIP Code Tabulation Areas (ZCTAs). Gourevitch and Kousky (2025) describe patterns and limitations in the federal Property and Casualty Market Intelligence (PCMI) data. Heitfield (2026) flags geographic selection concerns in Florida while studying hurricane-model uncertainty and premiums. Koller (2025) applies federal ZIP-level data to California insurance-market conditions.")
p("The present analysis extends these discussions through within-California comparisons of federal availability, recorded-count coverage, and hotspot membership under alternative definitions. Official source documentation is integral to this contribution: California termination fields include cancellations, federal nonrenewals exclude separately recorded cancellations, and subsequent California releases revise reporting methods and overlapping years.")
h("3. Data and measurement")
p("The primary input is the California Department of Insurance (CDI) ZIP workbook for 2015–2021, restricted to 2018–2021 (CDI, n.d.-a). It contains 8,503 ZIP-year observations and 2,323 distinct ZIP labels. New policies (N), renewed policies (R), insurer-initiated terminations (I), and policyholder-initiated terminations (U) are retained. The two termination categories include reported nonrenewals and cancellations (CDI, 2022a). CDI clarified the treatment of nonpayment as consumer-initiated starting in 2020; changes over time may therefore include reporting effects.")
p("The primary constructed normalizer is T = R + I + U. The insurer-initiated descriptive share is 100 I/T; the combined share is 100 (I + U)/T. These are indices of recorded transactions. T is not a verified renewal cohort, year-end stock, count of unique policies, or count of households. Zero denominators remain undefined.")
p("For the denominator sensitivity, D = N + R is used as an additional descriptive normalizer. CDI uses new-plus-renewed counts in published comparisons of termination activity. D also is not a verified at-risk renewal cohort, and I/D or (I+U)/D must not be interpreted as household probabilities. Annual event flows relative to such a denominator need not be bounded by 100%.")
p("Federal availability is determined from the FIO 2018–2022 workbook matched on ZIP and year. A finite numeric nonrenewal entry, including zero, is usable in this sample. All matched entries pass the original review screen. Unavailable observations have no federal ZIP-year match; absence alone does not distinguish disclosure suppression, collection coverage, or geography. The federal HO-3/HO-5 population and year-end stock denominator differ from California's broader residential collection.")
p("County context uses the fixed 2013 USDA Rural–Urban Continuum Codes: 1–3 for metropolitan counties and 4–9 for nonmetropolitan counties. Missing-county observations are retained in statewide totals and excluded from assigned county-context comparisons. Census sensitivity uses exact label membership in the fixed 2020 ZCTA Gazetteer. Such membership does not verify historical postal delivery type or insured-property location.")
h("4. Methods")
p("ZIP identifiers are preserved as five-character strings. The state panel is left-joined to federal values; missing measures are never replaced by zero. Original annual counts reconcile to 16 official state year-variable totals. The original complete R pipeline and its 44 regression checks are rerun before the extension. Supplementary Python independently imports the earlier California workbook and compares every study-year count with the R panel.")
p("Coverage is measured both by the fraction of ZIP-year records and by their share of summed T. Annual aggregate shares are formed by summing numerators and denominators before division. The geographic restriction effect is the visible-subset share minus the all-record share in percentage points. If w is the visible fraction of T, this difference equals (1−w)(s_visible−s_missing). This is an accounting identity, not a model of why observations are missing.")
p("The primary local rule requires T ≥ 100 and selects the annual highest 10% of I/T, including all cutoff ties. Definition comparisons use identical eligible samples and rank I/T and (I+U)/T separately. Retention is the shared count divided by the insurer-defined hotspot count; Jaccard overlap divides the shared count by the union. Rank agreement uses average-rank Spearman correlation.")
p("New definition sensitivity combines T minima of 50, 100 and 200 with top fractions of 5%, 10% and 20%. For paired denominator comparisons the T≥100 eligibility rule is kept fixed and D>0 is required for both scores. This separates the effect of normalization from changing the minimum-count population. Both event definitions are compared under each denominator, and each event definition is also compared across denominators.")
p("Each of the 58 known counties is excluded in turn, retaining unknown-county records in statewide totals. The eligible local sample and annual ranking cutoffs are recomputed after every exclusion. Aggregate selection, county-context gaps, definition retention and hotspot omission are recalculated. These are influence checks rather than uncertainty intervals.")
p("The later 2020–2023 California ZIP workbook is compared with the earlier release in 2020–2021 using new, renewed and combined termination counts. Both all-record totals and matched-key totals are reported. The later combined category cannot identify insurer and policyholder components separately; no allocation is imposed and no revisions are spliced into the primary historical panel.")
p("All new checks were added after inspection of the earlier report and are exploratory. No p-values are needed for these deterministic released-record comparisons. Reporting-period summaries are descriptive and do not estimate the causal effect of the 2020 clarification.")
h("5. Primary results reproduced")
cov=[]
hot=[]
for y,z in orig.groupby("year"):
    v=z[z.visible]
    cov.append({"year":y,"records":len(z),"visible":len(v),"record_pct":100*len(v)/len(z),"T_pct":100*v["T"].sum()/z["T"].sum()})
    e=z[z["T"]>=100];s=e.I/e["T"];m=s>=s.sort_values(ascending=False).iloc[int(__import__("math").ceil(.1*len(e)))-1]
    hot.append({"year":y,"hotspots":int(m.sum()),"omitted":int((m&~e.visible).sum()),
      "omission_pct":100*(m&~e.visible).sum()/m.sum(),
      "omitted_T_pct":100*e.loc[m&~e.visible,"T"].sum()/e.loc[m,"T"].sum()})
table("Table 1. Federal availability",pd.DataFrame(cov),[("year","Year"),("records","State records"),("visible","Visible records"),("record_pct","Visible records %"),("T_pct","Visible T %")])
table("Table 2. Geographic restriction, primary normalizer",select[select.denominator=="T"],[("year","Year"),("all_insurer_pct","All %"),("visible_insurer_pct","Visible %"),("selection_difference_pp","Difference, pp")])
p("The visible subset covers 6,218 of 8,503 records. The missing 2,285 records represent approximately 0.157% of pooled T. Annual statewide differences remain very small, despite some higher descriptive shares among missing observations. Count weight explains the difference between geographic-record absence and aggregate impact.")
table("Table 3. Primary hotspot omission",pd.DataFrame(hot),[("year","Year"),("hotspots","Hotspots"),("omitted","Omitted"),("omission_pct","Omitted %"),("omitted_T_pct","Hotspot T omitted %")])
table("Table 4. Primary definition agreement",base,[("year","Year"),("insurer_hotspots","Insurer hotspots"),("shared","Shared"),("retention_pct","Retention %"),("jaccard_pct","Jaccard %"),("spearman","Spearman")])
p("The original pooled stable-cohort analysis retains 1,554 ZIPs meeting T≥100 in each of four years. Its 156 pooled hotspots include four with an incomplete federal history, representing 0.156989% of pooled hotspot T. This differs from annual omission because eligibility and the missing-history definition change. The original metro–nonmetro gap changes by at most 0.015993 percentage points on all positive-T records.")
p("The original primary lists share 62, 123, 116 and 103 hotspots out of 157 in 2018–2021. The combined numerator changes local identification; its higher aggregate level is mechanically expected and is not itself a novel finding. Original Census-label-matched checks retain the conclusion of definition disagreement. These results describe ZIP labels, not verified populations of residential communities.")
h("6. Additional robustness and release reconciliation")
p(f"Across 36 annual combinations of minimum count and top fraction, insurer-hotspot retention is {span(grid.retention_pct)}%. The supplement reports every specification rather than selecting only the largest disagreement. Changing the minimum alters the eligible population, so differences across rows are not attributed solely to estimator precision.")
table("Table 5. Alternative-normalizer definition agreement, T ≥ 100, D > 0, top 10%",newden,[("year","Year"),("eligible","Eligible"),("insurer_hotspots","Insurer hotspots"),("shared","Shared"),("retention_pct","Retention %"),("jaccard_pct","Jaccard %")])
table("Table 6. Hotspot retention when only the denominator changes",dchange,[("year","Year"),("denominator","Numerator I or C"),("insurer_hotspots","T-based hotspots"),("shared","Shared with D"),("retention_pct","Retention %")])
p(f"With D = new plus renewed policies, insurer-versus-combined retention ranges from {span(newden.retention_pct)}% under the paired primary local rule. The denominator-only comparison in Table 6 separates this issue from event-definition disagreement. Any sample losses from D=0 are tabulated in the supplement; they must not be counted as low scores.")
table("Table 7. Statewide selection differences under both normalizers",select,[("year","Year"),("denominator","Normalizer"),("all_insurer_pct","All %"),("visible_insurer_pct","Visible %"),("selection_difference_pp","Difference, pp")])
p(f"Across county exclusions, statewide visible-minus-all differences range from {span(om.selection_difference_pp,6)} percentage points. Definition retention ranges from {span(om.retention_pct)}%, and insurer-hotspot omission ranges from {span(om.insurer_hotspot_omission_pct)}%. These ranges pool counties and years; year-specific results and the county producing each extreme are provided in the supplement.")
rall=rev[rev["sample"]=="All records in each release"]
table("Table 8. Overlapping-release count comparisons",rall,[("year","Year"),("metric","N, R or C"),("old_count","Earlier count"),("later_count","Later count"),("difference","Later minus earlier"),("change_pct","Change %")])
p("N denotes new policies, R renewed policies, and C the combined termination count. The releases are compared on their published definitions; common-key results are separately provided. CDI's later documentation identifies improved reporting, removal of flat-cancellation inflation, and separation of Difference in Conditions (DIC) policies (CDI, n.d.-c). Cross-release differences therefore require substantive disclosure; they cannot simply be treated as random revisions or allocated between I and U.")
p(f"Across all records, the later release's combined termination count is {abs(float(rall[(rall.year==2020)&(rall.metric=='C')].iloc[0].change_pct)):.2f}% lower in 2020 and {abs(float(rall[(rall.year==2021)&(rall.metric=='C')].iloc[0].change_pct)):.2f}% lower in 2021. Similar differences remain on matched ZIP-year keys, so unmatched locations alone do not explain the revisions. These differences qualify the data-vintage scope of the benchmark.")
p("The historical insurer/policyholder decomposition remains tied to the older release because the later file does not supply the same split. Reconciliation does not establish that the old classifications are the best available measures of current conditions. The paper is a benchmark of specified historical releases.")
h("7. Discussion and limitations")
p("The reproduced primary results support aggregate robustness to the observed geographic restriction. They do not support a general claim that federal absence creates large statewide distortion. Local omission depends on the eligible count population. Definition and denominator checks show exactly which geographic conclusions depend on measurement choices; readers should use the complete tables when judging their stability.")
p("State and federal records cover different policy populations and count different events. This design cannot validate federal rate levels, identify every source of selection, infer household replacement coverage, or measure individual FAIR Plan transitions. The primary and alternative normalizers are descriptive constructions, and source transactions may not correspond to mutually exclusive unique policies.")
p("Later-release reconciliation and the 2020 reporting clarification limit temporal interpretation. New release differences must remain separate from insurer-specific outcomes that cannot be reconstructed. Even an independently reproduced extraction does not validate the underlying insurer submissions.")
p("Postal ZIP labels and Census ZCTAs are not interchangeable. The earlier source check for ZIP 93016 reproduces I=95, R=53 and U=7 in 2020 (T=155; I/T=61.29%), but does not independently verify reporting origin or insured-property geography. Threshold checks and label-matched sensitivity address some consequences without certifying that record as household-level risk evidence.")
p("The study is exploratory, covers one state and four historical years, and contains no causal identification or probability-based sampling inference. No statistical significance claim is attached to the calculated differences. Robustness is evaluated against declared alternatives, not by adding models to obtain a preferred result.")
h("8. Conclusion")
p("The California benchmark quantifies how published federal availability changes explicitly defined state summaries and hotspot representation. Aggregate geographic restriction effects are small in the original release. Local omission is concentrated among smaller records, while definition choice changes hotspot membership. The added denominator, county-influence and cross-release checks qualify the scope of those conclusions. Public insurance-data applications should disclose their vintage, numerator, normalizer, eligibility rule and geographic coverage together.")
h("Data, code and verification")
run_url=f"https://github.com/{os.getenv('GITHUB_REPOSITORY','sijanpoudel-hub/california-home-insurance-measurement')}/actions/runs/{os.getenv('GITHUB_RUN_ID','')}"
p("Code: https://github.com/sijanpoudel-hub/california-home-insurance-measurement . The extension and report generator are preserved on the analysis branch. This revision was generated only after the complete original R pipeline and supplementary checks succeeded. The 44 original regression checks verify reproduction of saved quantities; supplementary checks compare every original study-year count with an independent Python workbook import and reproduce the main selection and hotspot results. This is not independent validation of insurer submissions.")
p("Run record: "+run_url)
p("Input fingerprints, acquisition records, full numerical outputs, software versions and source references accompany the report. The 2020–2023 workbook has its own SHA-256 manifest. New robustness exercises are labelled exploratory. The reproducible numerical outputs are authoritative if a rounding difference appears in the displayed text.")
h("Declarations")
p("Funding: No external funding. Competing interests: None declared. Data and ethics: Publicly released aggregate records; no individual policyholder information. Generative AI assistance: ChatGPT assisted with research design, literature searches, source checks, code, execution, interpretation and manuscript preparation. The author remains responsible for reviewing the results, citations and submission.")
h("References")
refs=[
"California Department of Insurance. (2022a). Insurance Policy Count Data 2015–2021 [Fact sheet, December 2022]. https://www.insurance.ca.gov/01-consumers/200-wrr/upload/CDI-Fact-Sheet-Residential-Insurance-Market-Policy-Count-Data-December-2022.pdf",
"California Department of Insurance. (2022b). Number of New, Renewed, and Non-Renewed Homeowners’ Policies: County Analysis 2015–2021. https://www.insurance.ca.gov/01-consumers/200-wrr/upload/Residential-Insurance-Policy-Analysis-by-County-2015-to-2021-2.pdf",
"California Department of Insurance. (n.d.-a). Residential Property Voluntary Market New, Renewed and Nonrenewed Policies by ZIP, 2015–2021 [Excel workbook]. Official data portal: https://www.insurance.ca.gov/01-consumers/200-wrr/DataAnalysisOnWildfiresAndInsurance.cfm",
"California Department of Insurance. (n.d.-b). Residential Insurance Voluntary Market New, Renewed and Nonrenewed Policies by ZIP, 2020–2023 [Excel workbook]. https://www.insurance.ca.gov/01-consumers/200-wrr/upload/Residential-Insurance-Voluntary-Market-New-Renew-NonRenew-by-ZIP-2020-2023.xlsx",
"California Department of Insurance. (n.d.-c). Summary on Residential Insurance Policies and the FAIR Plan [Fact sheet; reporting revisions and DIC separation]. https://www.insurance.ca.gov/01-consumers/200-wrr/upload/CDI-Fact-Sheet-Summary-on-Residential-Insurance-Policies-and-the-FAIR-Plan.pdf",
"California Volunteers. (n.d.). Look up your county by ZIP code. https://www.californiavolunteers.ca.gov/look-up-your-county-by-zip-code/",
"Federal Insurance Office, U.S. Department of the Treasury. (2025a). Analyses of U.S. Homeowners Insurance Markets, 2018–2022: Climate-Related Risks and Other Factors. https://home.treasury.gov/system/files/311/Analyses_of_US_Homeowners_Insurance_Markets_2018-2022_Climate-Related_Risks_and_Other_Factors_0.pdf",
"Federal Insurance Office, U.S. Department of the Treasury. (2025b). Supporting Underlying Metrics and Disclaimer [Excel workbook]. https://home.treasury.gov/system/files/311/Supporting_Underlying_Metrics_and_Disclaimer_for_Analyses_of_US_Homeowners_Insurance_Markets_2018-2022.xlsx",
"Gourevitch, J. D., & Kousky, C. (2025). New homeowners insurance data reveals insights into market trends and suggests future research needs. Risk Management and Insurance Review, 28(2), 324–338. https://doi.org/10.1111/rmir.70010",
"Heitfield, E. (2026). Model Uncertainty and the Pricing of Hurricane Risk in Florida. FEDS 2026-016. https://doi.org/10.17016/FEDS.2026.016",
"Koller, S. (2025, May 27). California’s homeowners insurance market is a national bellwether. Harvard Joint Center for Housing Studies. https://www.jchs.harvard.edu/blog/californias-homeowners-insurance-market-national-bellwether",
"Liao, Y., Walls, M. A., Wibbenmeyer, M., & Pesek, S. (2022, November 30). Insurance availability and affordability under increasing wildfire risk in California. Resources for the Future. https://www.rff.org/publications/issue-briefs/insurance-availability-and-affordability-under-increasing-wildfire-risk-in-california/",
"U.S. Census Bureau. (2023). ZIP Code Tabulation Areas. https://www.census.gov/programs-surveys/geography/guidance/geo-areas/zctas.html",
"U.S. Census Bureau. (n.d.). 2020 Gazetteer Files [National ZCTA reference]. https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2020_Gazetteer/2020_Gaz_zcta_national.zip",
"U.S. Department of Agriculture, Economic Research Service. (n.d.). 2013 Rural–Urban Continuum Codes. https://ers.usda.gov/data-products/rural-urban-continuum-codes"]
for ref in refs:p(ref)
# Render shared blocks in Word and PDF; split table rows across pages safely.
def render(blocks,stem,title):
    doc=Document();sec=doc.sections[0];sec.top_margin=sec.bottom_margin=Inches(.7)
    sec.left_margin=sec.right_margin=Inches(.65)
    style=doc.styles["Normal"];style.font.name="Calibri";style.font.size=Pt(10.5)
    style.paragraph_format.space_after=Pt(6)
    doc.add_heading(title,0)
    styles=getSampleStyleSheet();styles.add(ParagraphStyle("Small",parent=styles["BodyText"],fontSize=7,leading=9));styles["BodyText"].fontSize=9;styles["BodyText"].leading=12
    styles["BodyText"].spaceAfter=7;styles["Title"].fontSize=18
    styles["Heading2"].fontSize=12;styles["Heading2"].spaceBefore=12
    styles["Small"].fontSize=7;styles["Small"].leading=9
    if font_path.exists():
        for sty in styles.byName.values():sty.fontName="DejaVuSans"
    story=[Paragraph(html.escape(title),styles["Title"]),Spacer(1,10)]
    markdown=["# "+title,""]
    for kind,b in blocks:
        if kind=="h":
            doc.add_heading(b,1);story.append(Paragraph(html.escape(b),styles["Heading2"]));markdown+=["## "+b,""]
        elif kind=="p":
            doc.add_paragraph(b);story.append(Paragraph(html.escape(b),styles["BodyText"]));markdown +=[b,""]
        elif kind=="table":
            caption,heads,rows=b;doc.add_paragraph(caption,style="Caption")
            t=doc.add_table(rows=1,cols=len(heads));t.style="Light Shading Accent 1"
            for c,v in zip(t.rows[0].cells,heads):c.text=v
            repeat=OxmlElement("w:tblHeader");t.rows[0]._tr.get_or_add_trPr().append(repeat)
            for row in rows:
                for c,v in zip(t.add_row().cells,row):
                    c.text=str(v)
                    for pa in c.paragraphs:
                        for ru in pa.runs:ru.font.size=Pt(8)
            story.append(Paragraph(html.escape(caption),styles["BodyText"]))
            cells=[[Paragraph(html.escape(str(v)),styles["Small"]) for v in r] for r in [heads]+rows]
            tb=Table(cells,colWidths=[7.2*inch/len(heads)]*len(heads),repeatRows=1,hAlign="LEFT")
            tb.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,0),colors.HexColor("#dce6f1")),
                ("VALIGN",(0,0),(-1,-1),"TOP"),("LINEBELOW",(0,0),(-1,0),.5,colors.grey),
                ("BOTTOMPADDING",(0,0),(-1,-1),5),("TOPPADDING",(0,0),(-1,-1),5),
                ("ROWBACKGROUNDS",(0,1),(-1,-1),[colors.white,colors.HexColor("#f5f7fa")])]))
            story +=[tb,Spacer(1,9)]
            markdown +=[caption,"","| "+" | ".join(heads)+" |","| "+" | ".join(["---"]*len(heads))+" |"]+["| "+" | ".join(map(str,r))+" |" for r in rows]+[""]
    footer=sec.footer.paragraphs[0];footer.alignment=2
    fld=OxmlElement("w:fldSimple");fld.set(qn("w:instr"),"PAGE");footer._p.append(fld)
    doc.save(D/(stem+".docx"))
    def page_num(canvas,document):
        canvas.setFont("Helvetica",8);canvas.drawRightString(7.8*inch,.35*inch,str(document.page))
    SimpleDocTemplate(str(D/(stem+".pdf")),pagesize=(8.5*inch,11*inch),
      leftMargin=.65*inch,rightMargin=.65*inch,topMargin=.65*inch,bottomMargin=.65*inch).build(story,onFirstPage=page_num,onLaterPages=page_num)
    (D/(stem+".md")).write_text("\n".join(markdown),encoding="utf-8")
render(B,"California_Home_Insurance_Research_Report_Revised",title)
B=[]
h("Purpose and interpretation")
p("This supplement reports all added exploratory checks. The original T≥100/top-10% analysis remains primary. Every numerical table is generated from the saved code outputs. New-plus-renewed normalization is descriptive, not an at-risk cohort; county exclusions rerank the remaining sample. No missing count or measure is imputed as zero.")
table("S1. Full definition sensitivity grid",grid,[("year","Year"),("minimum_T","Minimum T"),("top_fraction","Top fraction"),("eligible","Eligible"),("insurer_hotspots","Insurer hotspots"),("combined_hotspots","Combined hotspots"),("shared","Shared"),("retention_pct","Retention %"),("jaccard_pct","Jaccard %")])
table("S2. All paired denominator comparisons",den,[("year","Year"),("comparison","Comparison"),("denominator","Denominator or numerator"),("top_fraction","Top fraction"),("eligible","Eligible"),("shared","Shared"),("retention_pct","Retention %"),("jaccard_pct","Jaccard %")])
table("S3. Paired denominator sample accounting",read("extended_denominator_exclusions.csv"),[("year","Year"),("T100_eligible","T≥100"),("excluded_D_zero","D=0 excluded"),("paired_eligible","Paired sample")])
summ=[]
for y,z in om.groupby("year"):
    for metric in ["selection_difference_pp","gap_change_pp","retention_pct","insurer_hotspot_omission_pct"]:
        low=z.loc[z[metric].idxmin()];high=z.loc[z[metric].idxmax()]
        summ.append({"year":y,"metric":metric,"minimum":low[metric],"county_min":low.excluded_county,
        "maximum":high[metric],"county_max":high.excluded_county})
table("S4. Leave-one-county-out extremes",pd.DataFrame(summ),[("year","Year"),("metric","Metric"),("minimum","Minimum"),("county_min","Excluded county"),("maximum","Maximum"),("county_max","Excluded county")])
p("The complete 236-row influence table is supplied as extended_leave_one_county_out.csv. NONE is the full-sample baseline, and named counties are omitted individually. Unknown-county rows remain in statewide counts.")
table("S5. Release key coverage",read("extended_release_key_coverage.csv"),[("year","Year"),("both","Both"),("left_only","Earlier only"),("right_only","Later only")])
table("S6. All overlapping-release comparisons",rev,[("year","Year"),("sample","Sample"),("metric","Metric"),("old_count","Earlier count"),("later_count","Later count"),("difference","Difference"),("change_pct","Change %"),("common_keys_with_changed_count","Changed common keys")])
table("S7. Definition retention by reporting regime",read("extended_reporting_regime_summary.csv"),[("reporting_period","Reporting period"),("minimum_retention_pct","Minimum %"),("maximum_retention_pct","Maximum %")])
table("S8. Original hotspot-omission sensitivity grid",read("step9_hotspot_sensitivity.csv"),[("year","Year"),("minimum_count","Minimum T"),("top_fraction","Top fraction"),("hotspot_omission_pct","Hotspots omitted %"),("hotspot_count_omission_pct","Hotspot T omitted %")])
table("S9. Original Census-label hotspot sensitivity",read("submission_geography_hotspot_sensitivity.csv"),[("year","Year"),("sample","Sample"),("eligible_records","Eligible"),("hotspots","Hotspots"),("omitted_hotspots","Omitted"),("hotspot_omission_pct","Omission %")])
h("Verification")
p("Original R checks: "+str(len(read("reproducibility_checks.csv")))+". Supplementary checks: "+str(len(read("extended_independent_checks.csv")))+". Both reports must show all checks passed. Independent import checks verify extraction and calculations, not the accuracy of source insurer reporting.")
for ref in refs[:5]:p(ref)
render(B,"California_Home_Insurance_Robustness_Supplement","Additional robustness checks and release reconciliation")
# Concise run summary for users and GitHub job summary.
summary=[
"# Additional analysis completed","",
f"- Full definition-grid retention: {span(grid.retention_pct)}%.",
f"- Alternative-normalizer primary-rule definition retention: {span(newden.retention_pct)}%.",
f"- Leave-one-county-out selection differences: {span(om.selection_difference_pp,6)} percentage points.",
f"- Original checks passed: {len(read('reproducibility_checks.csv'))}.",
f"- Supplementary checks passed: {len(read('extended_independent_checks.csv'))}.",
"","## Overlapping-release comparisons","",rall.to_string(index=False),
"","The main historical panel remains unchanged; the revised report explains the scope of cross-release differences.",
"","## Files","","- California_Home_Insurance_Research_Report_Revised.docx",
"- California_Home_Insurance_Research_Report_Revised.pdf",
"- California_Home_Insurance_Robustness_Supplement.docx",
"- California_Home_Insurance_Robustness_Supplement.pdf",
"","Full CSV results and code are included in the downloadable archive.","",run_url]
(D/"RESULTS_SUMMARY.md").write_text("\n".join(summary),encoding="utf-8")
print("\n".join(summary))
if os.getenv("GITHUB_STEP_SUMMARY"):
    Path(os.environ["GITHUB_STEP_SUMMARY"]).write_text("\n".join(summary))
# Validate generated documents structurally and the number of checked tables.
for path in D.glob("*.docx"):
    dd=Document(path)
    assert len(dd.paragraphs)>10 and len(dd.tables)>=7,path
for path in D.glob("*.pdf"):
    assert path.read_bytes().startswith(b"%PDF") and path.stat().st_size>10000,path
print("Generated Word/PDF structure checks passed")

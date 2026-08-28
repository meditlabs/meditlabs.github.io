import os
from datetime import datetime

import oracledb
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st


st.set_page_config(page_title="DRG运营分析大盘", page_icon="🏥", layout="wide")
st.markdown(
    """
    <style>
    .block-container {
        max-width: 1680px;
        padding-top: 1.5rem;
        padding-bottom: 2rem;
    }
    h1 {
        margin-bottom: 0.15rem !important;
        font-size: 2.2rem !important;
    }
    h1 a, h2 a, h3 a {
        display: none !important;
    }
    div[data-testid="stMetric"] {
        min-height: 112px;
        padding: 15px 17px;
        border: 1px solid rgba(128, 128, 128, 0.22);
        border-radius: 12px;
        background: rgba(128, 128, 128, 0.06);
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
    }
    div[data-testid="stMetricLabel"] {
        font-size: 0.88rem;
        opacity: 0.82;
    }
    div[data-testid="stMetricValue"] {
        font-size: 1.72rem;
        line-height: 1.3;
        white-space: nowrap;
    }
    div[data-testid="stMetricDelta"] {
        font-size: 0.78rem;
    }
    div[data-testid="stHorizontalBlock"] {
        gap: 0.8rem;
    }
    div[data-testid="stExpander"] {
        margin-top: 0.5rem;
        border-radius: 12px;
    }
    .stTabs [data-baseweb="tab-list"] {
        gap: 0.25rem;
        margin-top: 0.7rem;
    }
    .stTabs [data-baseweb="tab"] {
        padding-left: 0.85rem;
        padding-right: 0.85rem;
    }
    </style>
    """,
    unsafe_allow_html=True,
)
st.title("🏥 DRG运营分析大盘")
st.caption("数据来源：XXX DRG 表")

DB_CONFIG = {
    "user": os.getenv("HIS_DB_USER", "his账号"),
    "password": os.getenv("HIS_DB_PASSWORD", "his密码"),
    "dsn": os.getenv("HIS_DB_DSN", "192.168.1.100:1521/HISDB"),
}


@st.cache_data(ttl=600, show_spinner="正在从Oracle读取DRG数据……")
def load_drg_data(start_month: str, end_month: str) -> pd.DataFrame:
    sql = """
        SELECT
            custom AS inpatient_no,
            num AS patient_name,
            extend3 AS hospital_area,
            extend4 AS discharge_dept_source,
            extend5 AS settle_population,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend6, '[^0-9.-]', ''), '')) AS drg_weight,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend7, '[^0-9.-]', ''), '')) AS payment_standard,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend10, '[^0-9.-]', ''), '')) AS drg_balance,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend12, '[^0-9.-]', ''), '')) AS total_cost_without_pre,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend14, '[^0-9.-]', ''), '')) AS stay_days,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend15, '[^0-9.-]', ''), '')) AS western_medicine_cost,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend16, '[^0-9.-]', ''), '')) AS chinese_patent_cost,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend17, '[^0-9.-]', ''), '')) AS herbal_medicine_cost,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend18, '[^0-9.-]', ''), '')) AS treatment_cost,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend19, '[^0-9.-]', ''), '')) AS examination_cost,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend20, '[^0-9.-]', ''), '')) AS laboratory_cost,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend22, '[^0-9.-]', ''), '')) AS operation_cost,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend23, '[^0-9.-]', ''), '')) AS anesthesia_cost,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend24, '[^0-9.-]', ''), '')) AS material_cost,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend25, '[^0-9.-]', ''), '')) AS operation_material_cost,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend110, '[^0-9.-]', ''), '')) AS high_value_material_cost,
            extend31 AS settle_category,
            extend32 AS payment_type,
            extend33 AS drg_code,
            extend34 AS drg_name,
            extend36 AS main_diagnosis_code,
            extend37 AS main_diagnosis_name,
            extend40 AS main_operation_code,
            extend41 AS main_operation_name,
            extend43 AS medical_group_leader,
            extend44 AS attending_doctor_source,
            extend47 AS settle_month,
            extend48 AS resident_doctor,
            extend49 AS settle_no,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend50, '[^0-9.-]', ''), '')) AS total_cost,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend51, '[^0-9.-]', ''), '')) AS advance_amount,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend52, '[^0-9.-]', ''), '')) AS drg_return_amount,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend53, '[^0-9.-]', ''), '')) AS settlement_rate,
            extend59 AS special_case,
            TO_NUMBER(NULLIF(REGEXP_REPLACE(extend60, '[^0-9.-]', ''), '')) AS final_drg_return_amount,
            charge_doc_code AS doctor_code,
            charge_doc_name AS doctor_name,
            dept_code,
            NVL(dept_name, extend4) AS dept_name,
            in_dept_code,
            in_dept_name,
            NVL(extend112, NVL(dept_name, extend4)) AS medical_group
        FROM DRG分析表
        WHERE extend47 >= :start_month
          AND extend47 <= :end_month
          AND REGEXP_LIKE(extend47, '^[0-9]{6}$')
    """
    with oracledb.connect(**DB_CONFIG) as connection:
        with connection.cursor() as cursor:
            cursor.arraysize = 2000
            cursor.execute(sql, start_month=start_month, end_month=end_month)
            columns = [item[0].lower() for item in cursor.description]
            return pd.DataFrame(cursor.fetchall(), columns=columns)


def safe_sum(series):
    return pd.to_numeric(series, errors="coerce").fillna(0).sum()


def safe_divide_series(numerator, denominator):
    """逐行安全除法，分母为0时返回0，并避免新版Pandas的降类型警告。"""
    numerator_values = pd.to_numeric(numerator, errors="coerce").astype(float)
    denominator_values = pd.to_numeric(denominator, errors="coerce").astype(float)
    result = pd.Series(0.0, index=numerator_values.index, dtype="float64")
    valid = denominator_values.notna() & denominator_values.ne(0)
    result.loc[valid] = numerator_values.loc[valid] / denominator_values.loc[valid]
    return result


def format_money(value):
    return f"¥{value:,.2f}"


def format_number(value):
    return f"{value:,.0f}"


def format_percent(value):
    return f"{value:.2f}%"


def format_settle_month(value):
    """将 YYYYMM 转为中文月份标签，并确保 Plotly 不按数值缩写。"""
    text = str(value).strip()
    if text.endswith(".0"):
        text = text[:-2]
    digits = "".join(character for character in text if character.isdigit())
    if len(digits) == 6:
        return f"{digits[:4]}年{digits[4:]}月"
    return text


def format_chinese_amount(value):
    """将 Plotly 金额刻度格式化为中文的万、亿，避免显示 M、B。"""
    value = float(value)
    absolute = abs(value)
    if absolute >= 100_000_000:
        text = f"{value / 100_000_000:.2f}".rstrip("0").rstrip(".")
        return f"{text}亿"
    if absolute >= 10_000:
        text = f"{value / 10_000:.2f}".rstrip("0").rstrip(".")
        return f"{text}万"
    return f"{value:,.0f}"


def use_chinese_amount_axis(fig, values, axis="y", colorbar=False):
    """为金额坐标轴生成中文刻度，同时保留零刻度。"""
    numeric = pd.to_numeric(pd.Series(values), errors="coerce").dropna()
    if numeric.empty:
        return fig

    low = min(0.0, float(numeric.min()))
    high = max(0.0, float(numeric.max()))
    if low == high:
        high = 1.0 if high == 0 else high * 1.1

    tick_values = [low + (high - low) * index / 5 for index in range(6)]
    tick_text = [format_chinese_amount(value) for value in tick_values]
    if axis == "x":
        fig.update_xaxes(tickmode="array", tickvals=tick_values, ticktext=tick_text)
    else:
        fig.update_yaxes(tickmode="array", tickvals=tick_values, ticktext=tick_text)
    if colorbar:
        fig.update_coloraxes(
            colorbar_tickmode="array",
            colorbar_tickvals=tick_values,
            colorbar_ticktext=tick_text,
        )
    return fig


def show_chart(fig):
    """统一渲染图表：隐藏右上角英文工具栏，并使用中文悬浮样式。"""
    fig.update_layout(
        font={"family": "Microsoft YaHei, SimHei, Arial", "size": 13},
        hoverlabel={"font_family": "Microsoft YaHei, SimHei, Arial"},
        legend={"title_text": ""},
    )
    st.plotly_chart(
        fig,
        width="stretch",
        config={
            "displayModeBar": False,
            "displaylogo": False,
            "responsive": True,
            "locale": "zh-CN",
        },
    )


def build_summary(data, group_field):
    result = data.groupby(group_field, dropna=False).agg(
        病例数=("inpatient_no", "count"),
        总费用=("total_cost", "sum"),
        垫付金额=("advance_amount", "sum"),
        DRG返款=("drg_return_amount", "sum"),
        盈亏金额=("drg_balance", "sum"),
        总权重=("drg_weight", "sum"),
        结付率加权值=("settlement_rate_weighted", "sum"),
        结付率权重=("settlement_rate_weight", "sum"),
        亏损病例数=("is_loss", "sum"),
    ).reset_index()
    result["均次费用"] = result["总费用"] / result["病例数"]
    result["CMI"] = result["总权重"] / result["病例数"]
    result["结付率"] = safe_divide_series(
        result["结付率加权值"], result["结付率权重"]
    )
    result["亏损病例占比"] = result["亏损病例数"] / result["病例数"] * 100
    result.drop(columns=["结付率加权值", "结付率权重"], inplace=True)
    return result


current_month = datetime.now().strftime("%Y%m")
with st.sidebar:
    st.header("查询条件")
    with st.form("query_form"):
        start_month = st.text_input("开始月份", value=f"{datetime.now().year}01", help="格式：YYYYMM")
        end_month = st.text_input("结束月份", value=current_month, help="格式：YYYYMM")
        submitted = st.form_submit_button("查询数据", type="primary", width="stretch")
    if st.button("清除数据缓存", width="stretch"):
        st.cache_data.clear()
        st.rerun()

if not (len(start_month) == 6 and len(end_month) == 6 and start_month.isdigit() and end_month.isdigit()):
    st.error("月份必须使用 YYYYMM 格式，例如 202601。")
    st.stop()
if start_month > end_month:
    st.error("开始月份不能晚于结束月份。")
    st.stop()

try:
    df = load_drg_data(start_month, end_month)
except Exception as exc:
    st.error(f"读取Oracle失败：{exc}")
    st.info("请检查数据库地址、服务名、账号、密码和网络连通性。")
    st.stop()

if df.empty:
    st.warning("当前月份范围没有查询到DRG数据。")
    st.stop()

numeric_columns = [
    "drg_weight", "payment_standard", "drg_balance", "total_cost_without_pre", "stay_days",
    "western_medicine_cost", "chinese_patent_cost", "herbal_medicine_cost", "treatment_cost",
    "examination_cost", "laboratory_cost", "operation_cost", "anesthesia_cost", "material_cost",
    "operation_material_cost", "high_value_material_cost", "total_cost", "advance_amount",
    "drg_return_amount", "settlement_rate", "final_drg_return_amount",
]
for column in numeric_columns:
    df[column] = pd.to_numeric(df[column], errors="coerce").fillna(0)

positive_rates = df.loc[df["settlement_rate"] > 0, "settlement_rate"]
if not positive_rates.empty and positive_rates.median() <= 2:
    df["settlement_rate"] *= 100
# 汇总结付率使用 extend51（垫付金额）加权，单病例结付率仍直接取 extend53。
valid_settlement_rate = (df["settlement_rate"] > 0) & (df["advance_amount"] > 0)
df["settlement_rate_weight"] = df["advance_amount"].where(valid_settlement_rate, 0)
df["settlement_rate_weighted"] = (
    df["settlement_rate"] * df["settlement_rate_weight"]
)
# 盈亏金额直接采用 extend10（DRG返款差额），不在 Python 中重新计算。
df["profit"] = df["drg_balance"]
df["is_loss"] = (df["profit"] < 0).astype(int)
df["settle_month_label"] = df["settle_month"].apply(format_settle_month)

with st.sidebar:
    hospital_options = sorted(df["hospital_area"].dropna().astype(str).unique().tolist())
    selected_hospitals = st.multiselect("院区", hospital_options, default=hospital_options)
    dept_options = sorted(df["dept_name"].dropna().astype(str).unique().tolist())
    selected_depts = st.multiselect("出院科室", dept_options)
    drg_options = sorted(df["drg_code"].dropna().astype(str).unique().tolist())
    selected_drg = st.multiselect("DRG组", drg_options)

filtered = df.copy()
if selected_hospitals:
    filtered = filtered[filtered["hospital_area"].astype(str).isin(selected_hospitals)]
if selected_depts:
    filtered = filtered[filtered["dept_name"].astype(str).isin(selected_depts)]
if selected_drg:
    filtered = filtered[filtered["drg_code"].astype(str).isin(selected_drg)]
if filtered.empty:
    st.warning("筛选条件下没有数据。")
    st.stop()

case_count = len(filtered)
total_cost = safe_sum(filtered["total_cost"])
advance_amount = safe_sum(filtered["advance_amount"])
total_return = safe_sum(filtered["drg_return_amount"])
profit = safe_sum(filtered["drg_balance"])
total_weight = safe_sum(filtered["drg_weight"])
cmi = total_weight / case_count if case_count else 0
loss_count = int(filtered["is_loss"].sum())
loss_rate = loss_count / case_count * 100 if case_count else 0
profit_case_count = int((filtered["profit"] > 0).sum())
profit_case_rate = profit_case_count / case_count * 100 if case_count else 0
average_profit = profit / case_count if case_count else 0
loss_values = filtered.loc[filtered["profit"] < 0, "profit"]
average_loss = float(loss_values.mean()) if not loss_values.empty else 0
valid_stay_days = filtered.loc[filtered["stay_days"] > 0, "stay_days"]
average_stay_days = float(valid_stay_days.mean()) if not valid_stay_days.empty else 0
profit_per_weight = profit / total_weight if total_weight else 0

drug_cost = safe_sum(
    filtered["western_medicine_cost"]
    + filtered["chinese_patent_cost"]
    + filtered["herbal_medicine_cost"]
)
material_total = safe_sum(
    filtered["material_cost"] + filtered["operation_material_cost"]
)
drug_cost_rate = drug_cost / total_cost * 100 if total_cost else 0
material_cost_rate = material_total / total_cost * 100 if total_cost else 0
ungrouped_mask = (
    filtered["drg_code"].isna()
    | filtered["drg_code"].astype(str).str.strip().isin(["", "None", "nan", "未入组"])
)
ungrouped_count = int(ungrouped_mask.sum())
ungrouped_rate = ungrouped_count / case_count * 100 if case_count else 0
settlement_weight = safe_sum(filtered["settlement_rate_weight"])
overall_settlement_rate = (
    safe_sum(filtered["settlement_rate_weighted"]) / settlement_weight
    if settlement_weight else 0
)

st.markdown("#### 核心运营指标")
core1, core2, core3, core4 = st.columns(4)
core1.metric("DRG病例数", format_number(case_count))
core2.metric("病例组合指数", f"{cmi:.3f}")
core3.metric("总体结付率", format_percent(overall_settlement_rate))
core4.metric("亏损病例占比", format_percent(loss_rate), delta=f"亏损{loss_count}例", delta_color="inverse")

money1, money2, money3, money4 = st.columns(4)
money1.metric("总费用", format_money(total_cost))
money2.metric("垫付金额", format_money(advance_amount))
money3.metric("DRG返款", format_money(total_return))
money4.metric("盈亏金额", format_money(profit))

with st.expander("查看更多运营效率指标", expanded=False):
    eff1, eff2, eff3, eff4 = st.columns(4)
    eff1.metric("总权重", f"{total_weight:,.2f}")
    eff2.metric("均次盈亏", format_money(average_profit))
    eff3.metric("每权重盈亏", format_money(profit_per_weight))
    eff4.metric("平均住院日", f"{average_stay_days:.2f}天")
    eff5, eff6, eff7, eff8 = st.columns(4)
    eff5.metric("盈利病例占比", format_percent(profit_case_rate), delta=f"盈利{profit_case_count}例")
    eff6.metric("平均亏损额", format_money(average_loss))
    eff7.metric("药占比 / 耗材占比", f"{drug_cost_rate:.2f}% / {material_cost_rate:.2f}%")
    eff8.metric("未入组率", format_percent(ungrouped_rate), delta=f"未入组{ungrouped_count}例", delta_color="inverse")

tab1, tab2, tab3, tab4, tab5, tab6, tab7, tab8 = st.tabs([
    "总体趋势", "科室分析", "DRG组分析", "费用结构", "亏损病例",
    "科室四象限", "亏损TOP20", "数据质量",
])

with tab1:
    monthly = filtered.groupby("settle_month_label").agg(
        病例数=("inpatient_no", "count"), 总费用=("total_cost", "sum"),
        垫付金额=("advance_amount", "sum"), DRG返款=("drg_return_amount", "sum"),
        盈亏金额=("drg_balance", "sum"),
        结付率加权值=("settlement_rate_weighted", "sum"),
        结付率权重=("settlement_rate_weight", "sum"), 总权重=("drg_weight", "sum"),
    ).reset_index().sort_values("settle_month_label")
    monthly["结付率"] = safe_divide_series(
        monthly["结付率加权值"], monthly["结付率权重"]
    )
    left, right = st.columns(2)
    with left:
        fig = px.bar(monthly, x="settle_month_label", y="病例数", title="月度DRG病例数",
                     labels={"settle_month_label": "结算月份"})
        fig.update_xaxes(type="category", categoryorder="array",
                         categoryarray=monthly["settle_month_label"].tolist())
        show_chart(fig)
    with right:
        fig = go.Figure(go.Bar(x=monthly["settle_month_label"], y=monthly["盈亏金额"],
                               marker_color=["#16a34a" if v >= 0 else "#dc2626" for v in monthly["盈亏金额"]]))
        fig.update_layout(title="月度DRG盈亏趋势", xaxis_title="结算月份", yaxis_title="盈亏金额")
        fig.update_xaxes(type="category", categoryorder="array",
                         categoryarray=monthly["settle_month_label"].tolist())
        fig.update_traces(
            hovertemplate="结算月份：%{x}<br>盈亏金额：￥%{y:,.2f}<extra></extra>"
        )
        use_chinese_amount_axis(fig, monthly["盈亏金额"], "y")
        show_chart(fig)
    fig = px.line(monthly, x="settle_month_label", y="结付率", markers=True, title="月度结付率趋势",
                  labels={"settle_month_label": "结算月份", "结付率": "结付率（%）"})
    fig.update_xaxes(type="category", categoryorder="array",
                     categoryarray=monthly["settle_month_label"].tolist())
    fig.add_hline(y=100, line_dash="dash", line_color="red", annotation_text="100%")
    show_chart(fig)

with tab2:
    dept_summary = build_summary(filtered, "dept_name").sort_values("盈亏金额")
    fig = px.bar(dept_summary, x="盈亏金额", y="dept_name", orientation="h", color="盈亏金额",
                 color_continuous_scale=["#dc2626", "#f8fafc", "#16a34a"], title="科室DRG盈亏分析",
                 labels={"dept_name": "出院科室", "盈亏金额": "盈亏金额"})
    use_chinese_amount_axis(fig, dept_summary["盈亏金额"], "x", colorbar=True)
    show_chart(fig)
    display_dept = dept_summary.rename(columns={"dept_name": "科室"}).sort_values("总费用", ascending=False)
    st.dataframe(display_dept, width="stretch", hide_index=True, column_config={
        "总费用": st.column_config.NumberColumn(format="￥%.2f"),
        "垫付金额": st.column_config.NumberColumn(format="￥%.2f"),
        "DRG返款": st.column_config.NumberColumn(format="￥%.2f"),
        "盈亏金额": st.column_config.NumberColumn(format="￥%.2f"),
        "均次费用": st.column_config.NumberColumn(format="￥%.2f"),
        "CMI": st.column_config.NumberColumn(format="%.3f"),
        "结付率": st.column_config.NumberColumn(format="%.2f%%"),
        "亏损病例占比": st.column_config.NumberColumn(format="%.2f%%"),
    })

with tab3:
    drg_summary = filtered.groupby(["drg_code", "drg_name"], dropna=False).agg(
        病例数=("inpatient_no", "count"), 总费用=("total_cost", "sum"),
        垫付金额=("advance_amount", "sum"), DRG返款=("drg_return_amount", "sum"),
        盈亏金额=("drg_balance", "sum"),
        支付标准=("payment_standard", "mean"), 总权重=("drg_weight", "sum"), 亏损病例数=("is_loss", "sum"),
        结付率加权值=("settlement_rate_weighted", "sum"),
        结付率权重=("settlement_rate_weight", "sum"),
    ).reset_index()
    drg_summary["结付率"] = safe_divide_series(
        drg_summary["结付率加权值"], drg_summary["结付率权重"]
    )
    drg_summary.drop(columns=["结付率加权值", "结付率权重"], inplace=True)
    drg_summary["均次费用"] = drg_summary["总费用"] / drg_summary["病例数"]
    drg_summary["CMI"] = drg_summary["总权重"] / drg_summary["病例数"]
    drg_summary["亏损病例占比"] = drg_summary["亏损病例数"] / drg_summary["病例数"] * 100
    max_cases = max(1, int(drg_summary["病例数"].max()))
    min_cases = st.slider("最少病例数", 1, max_cases, min(10, max_cases))
    drg_display = drg_summary[drg_summary["病例数"] >= min_cases].sort_values("盈亏金额")
    fig = px.scatter(drg_display, x="病例数", y="盈亏金额", size="总费用", color="CMI",
                     hover_name="drg_name", hover_data=["drg_code", "均次费用", "亏损病例占比"],
                     title="DRG组病例规模与盈亏分布",
                     labels={"drg_name": "DRG名称", "drg_code": "DRG编码", "CMI": "病例组合指数"})
    fig.add_hline(y=0, line_dash="dash", line_color="red")
    use_chinese_amount_axis(fig, drg_display["盈亏金额"], "y")
    show_chart(fig)
    st.dataframe(drg_display, width="stretch", hide_index=True, column_config={
        "总费用": st.column_config.NumberColumn(format="￥%.2f"), "垫付金额": st.column_config.NumberColumn(format="￥%.2f"),
        "DRG返款": st.column_config.NumberColumn(format="￥%.2f"),
        "盈亏金额": st.column_config.NumberColumn(format="￥%.2f"), "均次费用": st.column_config.NumberColumn(format="￥%.2f"),
        "支付标准": st.column_config.NumberColumn(format="￥%.2f"), "CMI": st.column_config.NumberColumn(format="%.3f"),
        "亏损病例占比": st.column_config.NumberColumn(format="%.2f%%"),
        "结付率": st.column_config.NumberColumn(format="%.2f%%"),
    })

with tab4:
    cost_mapping = {
        "西药费": "western_medicine_cost", "中成药费": "chinese_patent_cost", "中草药费": "herbal_medicine_cost",
        "治疗费": "treatment_cost", "检查费": "examination_cost", "检验费": "laboratory_cost",
        "手术费": "operation_cost", "麻醉费": "anesthesia_cost", "卫生材料费": "material_cost",
        "手术材料费": "operation_material_cost", "高值耗材费": "high_value_material_cost",
    }
    cost_data = pd.DataFrame({"费用类别": list(cost_mapping),
                              "金额": [safe_sum(filtered[c]) for c in cost_mapping.values()]})
    cost_data = cost_data[cost_data["金额"] != 0].sort_values("金额", ascending=False)
    if cost_data.empty:
        st.info("当前筛选范围没有费用结构数据。")
    else:
        left, right = st.columns(2)
        with left:
            fig = px.pie(cost_data, names="费用类别", values="金额", hole=0.45, title="费用构成占比")
            fig.update_traces(
                hovertemplate="费用类别：%{label}<br>金额：￥%{value:,.2f}<br>占比：%{percent}<extra></extra>"
            )
            show_chart(fig)
        with right:
            fig = px.bar(cost_data, x="金额", y="费用类别", orientation="h", title="各类费用金额")
            use_chinese_amount_axis(fig, cost_data["金额"], "x")
            fig.update_traces(
                hovertemplate="费用类别：%{y}<br>金额：￥%{x:,.2f}<extra></extra>"
            )
            show_chart(fig)

with tab5:
    loss_data = filtered[filtered["profit"] < 0].copy().sort_values("profit")
    loss_columns = ["settle_month", "inpatient_no", "patient_name", "dept_name", "medical_group", "doctor_name",
                    "drg_code", "drg_name", "main_diagnosis_name", "main_operation_name", "drg_weight", "total_cost",
                    "advance_amount", "drg_return_amount", "settlement_rate", "profit", "stay_days", "special_case"]
    loss_display = loss_data[loss_columns].rename(columns={
        "settle_month": "结算月份", "inpatient_no": "住院号", "patient_name": "姓名", "dept_name": "出院科室",
        "medical_group": "医疗组", "doctor_name": "主治医师", "drg_code": "DRG编码", "drg_name": "DRG名称",
        "main_diagnosis_name": "主要诊断", "main_operation_name": "主要手术", "drg_weight": "权重",
        "total_cost": "总费用", "advance_amount": "垫付金额", "drg_return_amount": "DRG返款",
        "settlement_rate": "结付率", "profit": "盈亏金额", "stay_days": "住院天数",
        "special_case": "特例单议",
    })
    st.dataframe(loss_display, width="stretch", hide_index=True, column_config={
        "总费用": st.column_config.NumberColumn(format="￥%.2f"), "垫付金额": st.column_config.NumberColumn(format="￥%.2f"),
        "DRG返款": st.column_config.NumberColumn(format="￥%.2f"), "结付率": st.column_config.NumberColumn(format="%.2f%%"),
        "盈亏金额": st.column_config.NumberColumn(format="￥%.2f"), "权重": st.column_config.NumberColumn(format="%.3f"),
    })
    csv_data = loss_display.to_csv(index=False, encoding="utf-8-sig").encode("utf-8-sig")
    st.download_button("下载亏损病例明细", data=csv_data,
                       file_name=f"DRG亏损病例_{start_month}_{end_month}.csv", mime="text/csv")

with tab6:
    st.caption("横轴为CMI，纵轴为每权重盈亏；气泡越大表示病例数越多，颜色越深表示亏损病例占比越高。")
    dept_quadrant = build_summary(filtered, "dept_name")
    dept_quadrant["每权重盈亏"] = safe_divide_series(
        dept_quadrant["盈亏金额"], dept_quadrant["总权重"]
    )
    quadrant_max_cases = max(1, int(dept_quadrant["病例数"].max()))
    quadrant_min_cases = st.slider(
        "科室最少病例数", 1, quadrant_max_cases,
        min(30, quadrant_max_cases), key="quadrant_min_cases",
    )
    quadrant_display = dept_quadrant[dept_quadrant["病例数"] >= quadrant_min_cases].copy()
    if quadrant_display.empty:
        st.info("当前病例数条件下没有可展示的科室。")
    else:
        cmi_reference = total_weight / case_count if case_count else 0
        profit_weight_reference = profit_per_weight
        fig = px.scatter(
            quadrant_display,
            x="CMI",
            y="每权重盈亏",
            size="病例数",
            color="亏损病例占比",
            hover_name="dept_name",
            hover_data={
                "病例数": True,
                "盈亏金额": ":,.2f",
                "每权重盈亏": ":,.2f",
                "结付率": ":.2f",
                "亏损病例占比": ":.2f",
            },
            color_continuous_scale="RdYlGn_r",
            title="科室CMI—每权重盈亏四象限",
            labels={"dept_name": "科室", "亏损病例占比": "亏损病例占比（%）"},
        )
        fig.add_vline(x=cmi_reference, line_dash="dash", line_color="#64748b",
                      annotation_text="全院CMI")
        fig.add_hline(y=profit_weight_reference, line_dash="dash", line_color="#64748b",
                      annotation_text="全院每权重盈亏")
        use_chinese_amount_axis(fig, quadrant_display["每权重盈亏"], "y")
        show_chart(fig)
        st.dataframe(
            quadrant_display.sort_values("每权重盈亏", ascending=False),
            width="stretch",
            hide_index=True,
            column_config={
                "总费用": st.column_config.NumberColumn(format="￥%.2f"),
                "垫付金额": st.column_config.NumberColumn(format="￥%.2f"),
                "DRG返款": st.column_config.NumberColumn(format="￥%.2f"),
                "盈亏金额": st.column_config.NumberColumn(format="￥%.2f"),
                "均次费用": st.column_config.NumberColumn(format="￥%.2f"),
                "每权重盈亏": st.column_config.NumberColumn(format="￥%.2f"),
                "CMI": st.column_config.NumberColumn(format="%.3f"),
                "结付率": st.column_config.NumberColumn(format="%.2f%%"),
                "亏损病例占比": st.column_config.NumberColumn(format="%.2f%%"),
            },
        )

with tab7:
    loss_drg_top = filtered.groupby(["drg_code", "drg_name"], dropna=False).agg(
        病例数=("inpatient_no", "count"),
        总费用=("total_cost", "sum"),
        垫付金额=("advance_amount", "sum"),
        DRG返款=("drg_return_amount", "sum"),
        盈亏金额=("drg_balance", "sum"),
        总权重=("drg_weight", "sum"),
        亏损病例数=("is_loss", "sum"),
    ).reset_index()
    loss_drg_top["均次盈亏"] = loss_drg_top["盈亏金额"] / loss_drg_top["病例数"]
    loss_drg_top["亏损病例占比"] = (
        loss_drg_top["亏损病例数"] / loss_drg_top["病例数"] * 100
    )
    loss_drg_top["DRG组"] = (
        loss_drg_top["drg_code"].fillna("未入组").astype(str)
        + "｜"
        + loss_drg_top["drg_name"].fillna("无分组名称").astype(str)
    )
    loss_drg_top = loss_drg_top[loss_drg_top["盈亏金额"] < 0].nsmallest(20, "盈亏金额")
    if loss_drg_top.empty:
        st.success("当前筛选范围没有汇总亏损的DRG组。")
    else:
        chart_data = loss_drg_top.sort_values("盈亏金额", ascending=False)
        fig = px.bar(
            chart_data, x="盈亏金额", y="DRG组", orientation="h",
            color="亏损病例占比", color_continuous_scale="Reds",
            hover_data=["病例数", "均次盈亏", "亏损病例数"],
            title="亏损金额最多的DRG组TOP20",
        )
        use_chinese_amount_axis(fig, chart_data["盈亏金额"], "x")
        show_chart(fig)
        st.dataframe(
            loss_drg_top[["drg_code", "drg_name", "病例数", "亏损病例数", "亏损病例占比",
                          "总费用", "垫付金额", "DRG返款", "盈亏金额", "均次盈亏", "总权重"]],
            width="stretch", hide_index=True,
            column_config={
                "总费用": st.column_config.NumberColumn(format="￥%.2f"),
                "垫付金额": st.column_config.NumberColumn(format="￥%.2f"),
                "DRG返款": st.column_config.NumberColumn(format="￥%.2f"),
                "盈亏金额": st.column_config.NumberColumn(format="￥%.2f"),
                "均次盈亏": st.column_config.NumberColumn(format="￥%.2f"),
                "亏损病例占比": st.column_config.NumberColumn(format="%.2f%%"),
            },
        )

with tab8:
    duplicate_mask = filtered.duplicated(subset=["inpatient_no", "settle_no"], keep=False)
    quality_masks = {
        "DRG未入组": ungrouped_mask,
        "权重为空或小于等于0": filtered["drg_weight"] <= 0,
        "总费用为空或小于等于0": filtered["total_cost"] <= 0,
        "结付率异常（小于0或大于500%）": (
            (filtered["settlement_rate"] < 0) | (filtered["settlement_rate"] > 500)
        ),
        "住院天数异常（小于等于0或大于365天）": (
            (filtered["stay_days"] <= 0) | (filtered["stay_days"] > 365)
        ),
        "住院号和结算单据号重复": duplicate_mask,
    }
    quality_summary = pd.DataFrame([
        {
            "问题类型": issue,
            "记录数": int(mask.sum()),
            "占比": float(mask.sum()) / case_count * 100 if case_count else 0,
        }
        for issue, mask in quality_masks.items()
    ]).sort_values("记录数", ascending=False)
    q1, q2, q3 = st.columns(3)
    quality_record_mask = pd.Series(False, index=filtered.index)
    for mask in quality_masks.values():
        quality_record_mask |= mask
    q1.metric("问题类型数", format_number((quality_summary["记录数"] > 0).sum()))
    q2.metric("存在问题的记录数", format_number(quality_record_mask.sum()))
    q3.metric("问题记录占比", format_percent(quality_record_mask.mean() * 100 if case_count else 0))
    st.dataframe(
        quality_summary, width="stretch", hide_index=True,
        column_config={"占比": st.column_config.NumberColumn(format="%.2f%%")},
    )

    issue_labels = pd.Series("", index=filtered.index, dtype="object")
    for issue, mask in quality_masks.items():
        issue_labels.loc[mask] = issue_labels.loc[mask].apply(
            lambda current: f"{current}；{issue}" if current else issue
        )
    quality_details = filtered.loc[quality_record_mask, [
        "settle_month", "inpatient_no", "patient_name", "settle_no", "dept_name",
        "drg_code", "drg_name", "drg_weight", "total_cost", "advance_amount",
        "drg_return_amount", "drg_balance", "settlement_rate", "stay_days",
    ]].copy()
    quality_details.insert(0, "问题类型", issue_labels.loc[quality_record_mask])
    quality_details.rename(columns={
        "settle_month": "结算月份", "inpatient_no": "住院号", "patient_name": "姓名",
        "settle_no": "结算单据号", "dept_name": "科室", "drg_code": "DRG编码",
        "drg_name": "DRG名称", "drg_weight": "权重", "total_cost": "总费用",
        "advance_amount": "垫付金额", "drg_return_amount": "DRG返款",
        "drg_balance": "盈亏金额", "settlement_rate": "结付率", "stay_days": "住院天数",
    }, inplace=True)
    st.dataframe(
        quality_details, width="stretch", hide_index=True,
        column_config={
            "总费用": st.column_config.NumberColumn(format="￥%.2f"),
            "垫付金额": st.column_config.NumberColumn(format="￥%.2f"),
            "DRG返款": st.column_config.NumberColumn(format="￥%.2f"),
            "盈亏金额": st.column_config.NumberColumn(format="￥%.2f"),
            "结付率": st.column_config.NumberColumn(format="%.2f%%"),
        },
    )
    quality_csv = quality_details.to_csv(index=False, encoding="utf-8-sig").encode("utf-8-sig")
    st.download_button(
        "下载数据质量问题明细", data=quality_csv,
        file_name=f"DRG数据质量问题_{start_month}_{end_month}.csv", mime="text/csv",
    )
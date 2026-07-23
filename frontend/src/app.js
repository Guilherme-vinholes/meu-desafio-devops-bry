const signBtn = document.getElementById("sign-btn");
const refreshBtn = document.getElementById("refresh-btn");
const documentInput = document.getElementById("document");
const errorEl = document.getElementById("error");
const resultEl = document.getElementById("result");
const historyBody = document.getElementById("history-body");

function showError(message) {
  errorEl.textContent = message;
  errorEl.classList.remove("hidden");
}

function clearError() {
  errorEl.classList.add("hidden");
  errorEl.textContent = "";
}

function truncate(value, length = 60) {
  return value.length > length ? `${value.slice(0, length)}...` : value;
}

async function signDocument() {
  clearError();
  const document_ = documentInput.value.trim();
  if (!document_) {
    showError("Digite algum texto antes de assinar.");
    return;
  }

  signBtn.disabled = true;
  try {
    const res = await fetch("/api/sign", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ document: document_ }),
    });
    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      throw new Error(body.error || `Erro ${res.status}`);
    }
    const data = await res.json();

    document.getElementById("result-id").textContent = data.id;
    document.getElementById("result-hash").textContent = data.document_hash;
    document.getElementById("result-signature").textContent = truncate(data.signature, 120);
    document.getElementById("result-date").textContent = new Date(data.signed_at).toLocaleString("pt-BR");
    document.getElementById("result-host").textContent = data.handled_by;
    resultEl.classList.remove("hidden");

    await loadHistory();
  } catch (err) {
    showError(err.message || "Falha ao assinar o documento.");
  } finally {
    signBtn.disabled = false;
  }
}

async function loadHistory() {
  try {
    const res = await fetch("/api/signatures?limit=10");
    if (!res.ok) return;
    const data = await res.json();

    historyBody.innerHTML = "";
    for (const sig of data.signatures) {
      const row = document.createElement("tr");
      row.innerHTML = `
        <td>${sig.id}</td>
        <td class="mono">${truncate(sig.document_hash, 24)}</td>
        <td>${new Date(sig.created_at).toLocaleString("pt-BR")}</td>
        <td class="mono">${data.handled_by}</td>
      `;
      historyBody.appendChild(row);
    }
  } catch {
    // histórico é best-effort; falha aqui não deve travar a assinatura
  }
}

signBtn.addEventListener("click", signDocument);
refreshBtn.addEventListener("click", loadHistory);
window.addEventListener("load", loadHistory);

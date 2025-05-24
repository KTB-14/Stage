const dropzone = document.getElementById('dropzone');
const fileInput = document.getElementById('fileInput');
const selectBtn = document.getElementById('selectFile');
const statusDiv = document.getElementById('status');
const statusText = document.getElementById('statusText');
const downloadDiv = document.getElementById('downloadLink');

selectBtn.onclick = () => fileInput.click();
fileInput.onchange = () => uploadFile(fileInput.files[0]);

['dragenter', 'dragover'].forEach(evt => {
  dropzone.addEventListener(evt, e => {
    e.preventDefault();
    dropzone.classList.add('hover');
  });
});
['dragleave', 'drop'].forEach(evt => {
  dropzone.addEventListener(evt, e => {
    e.preventDefault();
    dropzone.classList.remove('hover');
  });
});
dropzone.addEventListener('drop', e => {
  if (e.dataTransfer.files.length) uploadFile(e.dataTransfer.files[0]);
});

async function uploadFile(file) {
  if (!file.type === 'application/pdf') return alert('Seuls les PDF sont autorisés.');
  if (file.size > 50 * 1024 * 1024) return alert('Fichier trop volumineux (>50 Mo).');

  statusDiv.classList.remove('hidden');
  statusText.textContent = 'Téléversement…';
  downloadDiv.innerHTML = ''; // réinitialiser

  const form = new FormData();
  form.append('files', file);

  const uploadRes = await fetch('/api/upload', {
    method: 'POST',
    body: form
  });
  if (!uploadRes.ok) return showError('Échec du téléversement.');

  const { job_id } = await uploadRes.json();
  checkStatus(job_id);
}

async function checkStatus(jobId) {
  statusText.textContent = 'Traitement en cours…';
  const res = await fetch(`/api/status/${jobId}`);
  const data = await res.json();

  if (data.status === 'done') {
    statusText.textContent = 'Terminé !';
    if (Array.isArray(data.files)) {
      downloadDiv.innerHTML = '<h4>Fichiers disponibles :</h4>';
      data.files.forEach(file => {
        const link = document.createElement('a');
        link.href = `/api/download/${jobId}/${file}`;
        link.textContent = `📥 ${file}`;
        link.className = 'download-link';
        link.setAttribute('download', file);

        const wrapper = document.createElement('div');
        wrapper.appendChild(link);
        downloadDiv.appendChild(wrapper);
      });
    } else {
      showError('Aucun fichier trouvé.');
    }
  } else if (data.status === 'error') {
    showError(data.details || 'Erreur pendant le traitement.');
  } else {
    setTimeout(() => checkStatus(jobId), 2000);
  }
}

function showError(msg) {
  statusText.textContent = `❌ ${msg}`;
}

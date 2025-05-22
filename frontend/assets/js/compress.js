const dropzone = document.getElementById('dropzone');
const fileInput = document.getElementById('fileInput');
const selectBtn = document.getElementById('selectFile');
const statusDiv = document.getElementById('status');
const statusText = document.getElementById('statusText');
const downloadDiv = document.getElementById('downloadLink');

selectBtn.onclick = () => fileInput.click();

fileInput.onchange = (e) => {
  const files = Array.from(e.target.files);
  if (files.length) {
    uploadFiles(files);
  }
};

['dragenter', 'dragover'].forEach(evt => {
  dropzone.addEventListener(evt, e => {
    e.preventDefault();
    e.stopPropagation();
    dropzone.classList.add('hover');
  });
});

['dragleave', 'drop'].forEach(evt => {
  dropzone.addEventListener(evt, e => {
    e.preventDefault();
    e.stopPropagation();
    dropzone.classList.remove('hover');
  });
});

dropzone.addEventListener('drop', e => {
  const files = Array.from(e.dataTransfer.files);
  if (files.length) {
    uploadFiles(files);
  }
});

async function uploadFiles(files) {
  const invalid = files.find(f => f.type !== 'application/pdf');
  if (invalid) {
    showError('Seuls les fichiers PDF sont autorisés');
    return;
  }

  try {
    statusDiv.classList.remove('hidden');
    statusText.innerHTML = `
      <div class="font-medium">Téléversement en cours...</div>
      <div class="text-sm text-gray-500">${files.length} fichiers PDF sélectionnés</div>
    `;

    const formData = new FormData();
    files.forEach(file => formData.append('files', file));

    const uploadRes = await fetch('/api/upload', {
      method: 'POST',
      body: formData
    });

    if (!uploadRes.ok) throw new Error('Échec du téléversement');

    const { job_id } = await uploadRes.json();
    await checkStatus(job_id);
  } catch (error) {
    showError(error.message);
  }
}

async function checkStatus(jobId) {
  try {
    statusText.innerHTML = `
      <div class="font-medium">Traitement en cours...</div>
      <div class="text-sm text-gray-500">Veuillez patienter pendant que nous traitons vos fichiers</div>
    `;

    const response = await fetch(`/api/status/${jobId}`);
    const data = await response.json();

    if (data.status === 'done') {
      statusText.innerHTML = `
        <div class="font-medium text-green-600">Traitement terminé !</div>
        <div class="text-sm text-gray-500">Vos fichiers sont prêts à être téléchargés</div>
      `;
      await displayDownloadLinks(jobId);
    } else if (data.status === 'error') {
      throw new Error(data.details || 'Erreur pendant le traitement');
    } else {
      setTimeout(() => checkStatus(jobId), 2000);
    }
  } catch (error) {
    showError(error.message);
  }
}

async function displayDownloadLinks(jobId) {
  downloadDiv.classList.remove('hidden');
  downloadDiv.innerHTML = '';

  try {
    const response = await fetch(`/api/download/${jobId}`);
    const data = await response.json();

    data.files.forEach(file => {
      const a = document.createElement('a');
      a.href = `/api/download/${jobId}/${file}`;
      a.download = file;
      a.textContent = `📥 Télécharger ${file}`;
      a.style.display = 'block';
      a.style.margin = '0.5rem 0';
      downloadDiv.appendChild(a);
    });
  } catch (error) {
    showError("Erreur lors du chargement des liens de téléchargement");
  }
}

function showError(message) {
  statusDiv.classList.remove('hidden');
  statusText.innerHTML = `
    <div class="text-red-600 font-medium">Erreur</div>
    <div class="text-sm text-gray-500">${message}</div>
  `;
}

function formatFileSize(bytes) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

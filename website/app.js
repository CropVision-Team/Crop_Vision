// CropVision AI — Modern Interactive Portal Logic

document.addEventListener('DOMContentLoaded', () => {

  // ─── 0. Theme Toggle (Light / Dark Mode) ───
  const themeToggleBtn = document.getElementById('themeToggleBtn');
  const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  const savedTheme = localStorage.getItem('cropvision-theme');
  const initialTheme = savedTheme || (prefersDark ? 'dark' : 'light');

  document.documentElement.setAttribute('data-theme', initialTheme);

  if (themeToggleBtn) {
    themeToggleBtn.addEventListener('click', () => {
      const activeTheme = document.documentElement.getAttribute('data-theme');
      const newTheme = activeTheme === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', newTheme);
      localStorage.setItem('cropvision-theme', newTheme);
    });
  }

  // ─── 1. Mobile Navigation Toggle ───
  const navToggle = document.getElementById('navToggle');
  const navMenu = document.getElementById('navMenu');

  if (navToggle && navMenu) {
    navToggle.addEventListener('click', () => {
      navMenu.classList.toggle('active');
    });
    document.querySelectorAll('.nav-link').forEach(link => {
      link.addEventListener('click', () => navMenu.classList.remove('active'));
    });
  }

  // ─── 2. Pipeline Simulator Demo ───
  const simData = {
    diseased: {
      image: 'Tomato Leaf (Early Blight)',
      verification: '<span class="pill pill-success">✓ Passed</span> Laplacian Variance: 248.5 (>100) • Green Ratio: 68.2%',
      classification: '<span class="pill pill-success">Detected</span> Tomato Early Blight (94.2% confidence)',
      severity: '<span class="pill pill-amber">G2 Moderate</span> Infected Leaf Area: <strong>24.8%</strong>',
      recommendation: 'Spray Copper Hydroxide or Chlorothalonil @ 2g/L. Prune infected lower foliage, avoid overhead wetting.'
    },
    healthy: {
      image: 'Apple Leaf (Healthy Tissue)',
      verification: '<span class="pill pill-success">✓ Passed</span> Laplacian Variance: 312.0 (>100) • Green Ratio: 89.4%',
      classification: '<span class="pill pill-success">Detected</span> Apple Healthy (98.6% confidence)',
      severity: '<span class="pill pill-success">G0 Pristine</span> Infected Leaf Area: <strong>0.2%</strong>',
      recommendation: 'No chemical intervention required. Maintain standard irrigation and seasonal foliar monitoring.'
    },
    blurry: {
      image: 'Out-of-Focus Field Photograph',
      verification: '<span class="pill pill-danger">✕ Rejected</span> Laplacian Variance: 42.1 (<100 threshold) • Image too blurry',
      classification: '<span class="pill pill-muted">Blocked</span> Did not submit to MobileViT (saved network bandwidth)',
      severity: '<span class="pill pill-muted">N/A</span> Quality gate check failed',
      recommendation: 'Hold smartphone steady 15–20cm above the leaf and ensure adequate daylight before retaking.'
    }
  };

  const simSampleBtns = document.querySelectorAll('.sim-sample-btn');
  const simImage = document.getElementById('simImage');
  const simVerification = document.getElementById('simVerification');
  const simClassification = document.getElementById('simClassification');
  const simSeverity = document.getElementById('simSeverity');
  const simRecommendation = document.getElementById('simRecommendation');

  simSampleBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      simSampleBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const sample = btn.getAttribute('data-sample');
      const d = simData[sample];
      if (d) {
        simImage.textContent = d.image;
        simVerification.innerHTML = d.verification;
        simClassification.innerHTML = d.classification;
        simSeverity.innerHTML = d.severity;
        simRecommendation.textContent = d.recommendation;
      }
    });
  });

  // ─── 3. "How We Built It" Deep Dive Tabs ───
  const deepdiveTabs = document.querySelectorAll('.deepdive-tab');
  const deepdivePanels = document.querySelectorAll('.deepdive-panel');

  deepdiveTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      const part = tab.getAttribute('data-part');
      deepdiveTabs.forEach(t => t.classList.remove('active'));
      deepdivePanels.forEach(p => p.classList.remove('active'));
      tab.classList.add('active');
      const targetPanel = document.getElementById('part-' + part);
      if (targetPanel) targetPanel.classList.add('active');
    });
  });

  // ─── 4. Interactive Severity Playground ───
  const severitySlider = document.getElementById('severitySlider');
  const sliderDisplayVal = document.getElementById('sliderDisplayVal');
  const dynamicStageBadge = document.getElementById('dynamicStageBadge');
  const stageCode = document.getElementById('stageCode');
  const stageName = document.getElementById('stageName');
  const stageThreshold = document.getElementById('stageThreshold');
  const stageUrgency = document.getElementById('stageUrgency');
  const rxOrganic = document.getElementById('rxOrganic');
  const rxChemical = document.getElementById('rxChemical');
  const rxCultural = document.getElementById('rxCultural');

  const stageConfigs = {
    G0: {
      code: 'G0',
      name: 'Healthy Foliage',
      className: 'stage-g0',
      threshold: '0% – 2% Affected Area',
      urgency: 'Preventive Status • Routine Care',
      organic: 'Neem oil 0.3% foliar spray for preventive pest repulsion.',
      chemical: 'No chemical intervention required. Protect beneficial insects.',
      cultural: 'Maintain drip irrigation and scheduled weeding.'
    },
    G1: {
      code: 'G1',
      name: 'Mild Infection',
      className: 'stage-g1',
      threshold: '2% – 15% Affected Area',
      urgency: 'Action Recommended Within 5 Days',
      organic: 'Bacillus subtilis bio-fungicide or Neem oil @ 5ml/L.',
      chemical: 'Preventive protective spray: Mancozeb 75% WP @ 2.0g/L.',
      cultural: 'Prune isolated lower blighted leaves; avoid leaf wetting.'
    },
    G2: {
      code: 'G2',
      name: 'Moderate Infection',
      className: 'stage-g2',
      threshold: '15% – 40% Affected Area',
      urgency: 'Action Required Within 48 Hours',
      organic: 'Copper Hydroxide 77% WP @ 2.0g/L or Trichoderma foliar spray.',
      chemical: 'Chlorothalonil 75% WP @ 2.5g/L or Azoxystrobin 23% SC @ 1ml/L.',
      cultural: 'Stake vines for canopy airflow; sanitize shears between cuts.'
    },
    G3: {
      code: 'G3',
      name: 'Critical Infection',
      className: 'stage-g3',
      threshold: '40% – 100% Affected Area',
      urgency: 'Emergency Action • Roguing & Containment',
      organic: 'Emergency plant isolation; burn or deeply bury ruined debris.',
      chemical: 'Systemic curative spray: Difenoconazole 25% EC + Mancozeb.',
      cultural: 'Immediately remove severely blighted vines to save adjacent crops.'
    }
  };

  function updateSeverity(val) {
    if (!sliderDisplayVal) return;
    sliderDisplayVal.textContent = val.toFixed(1) + '%';

    let currentStage = 'G0';
    if (val > 40.0) currentStage = 'G3';
    else if (val > 15.0) currentStage = 'G2';
    else if (val > 2.0) currentStage = 'G1';

    const cfg = stageConfigs[currentStage];
    if (!cfg) return;

    stageCode.textContent = cfg.code;
    stageName.textContent = cfg.name;
    stageThreshold.textContent = cfg.threshold;
    stageUrgency.textContent = cfg.urgency;
    rxOrganic.textContent = cfg.organic;
    rxChemical.textContent = cfg.chemical;
    rxCultural.textContent = cfg.cultural;

    dynamicStageBadge.className = 'dynamic-stage-badge ' + cfg.className;
  }

  if (severitySlider) {
    severitySlider.addEventListener('input', (e) => {
      updateSeverity(parseFloat(e.target.value));
    });
  }

  // ─── 5. Supported 38 Plant Classes Directory ───
  const plantClasses = [
    // Tomato
    { crop: 'Tomato', name: 'Early Blight', cat: 'fungal', desc: 'Concentric dark target-board rings on older foliage with chlorotic halos.' },
    { crop: 'Tomato', name: 'Late Blight', cat: 'fungal', desc: 'Water-soaked irregular greasy lesions rapidly turning necrotic under cool humidity.' },
    { crop: 'Tomato', name: 'Bacterial Spot', cat: 'bacterial', desc: 'Small angular water-soaked dark spots on leaves, stems, and green fruits.' },
    { crop: 'Tomato', name: 'Leaf Mold', cat: 'fungal', desc: 'Pale green/yellow spots on leaf upper surface; olive-velvety spores underneath.' },
    { crop: 'Tomato', name: 'Septoria Leaf Spot', cat: 'fungal', desc: 'Numerous small circular spots with gray centers and prominent black pycnidia.' },
    { crop: 'Tomato', name: 'Spider Mites (Two-Spotted)', cat: 'fungal', desc: 'Fine yellow-white foliar stippling accompanied by silky webbing on undersides.' },
    { crop: 'Tomato', name: 'Target Spot', cat: 'fungal', desc: 'Circular brown lesions with marked zonate rings and yellow chlorotic margins.' },
    { crop: 'Tomato', name: 'Yellow Leaf Curl Virus', cat: 'viral', desc: 'Severe leaf curling, upward cupping, stunting, and bushy apical shoot clusters.' },
    { crop: 'Tomato', name: 'Mosaic Virus', cat: 'viral', desc: 'Mottled alternating light and dark green foliage patterns and leaf distortion.' },
    { crop: 'Tomato', name: 'Healthy Leaf', cat: 'healthy', desc: 'Vibrant green, unblemished foliage with optimal vigor and normal leaf margins.' },

    // Potato
    { crop: 'Potato', name: 'Early Blight', cat: 'fungal', desc: 'Brown angular spots with concentric rings starting on lower mature leaves.' },
    { crop: 'Potato', name: 'Late Blight', cat: 'fungal', desc: 'Fast-spreading dark water-soaked patches leading to complete tuber/canopy collapse.' },
    { crop: 'Potato', name: 'Healthy Leaf', cat: 'healthy', desc: 'Uniform dark green leaves with crisp margins and active photosynthesis.' },

    // Apple
    { crop: 'Apple', name: 'Apple Scab', cat: 'fungal', desc: 'Olive-green to dark brown velvety foliar lesions causing premature leaf drop.' },
    { crop: 'Apple', name: 'Black Rot', cat: 'fungal', desc: 'Circular purple spots expanding into "frog-eye" lesions with light centers.' },
    { crop: 'Apple', name: 'Cedar Apple Rust', cat: 'fungal', desc: 'Bright yellow-orange raised pustules on upper surface; aecial tubes beneath.' },
    { crop: 'Apple', name: 'Healthy Leaf', cat: 'healthy', desc: 'Glossy deep green foliage free of necrotic lesions or powdery mildew.' },

    // Corn
    { crop: 'Corn', name: 'Cercospora Leaf Spot', cat: 'fungal', desc: 'Narrow rectangular tan-gray lesions strictly delimited by leaf veins.' },
    { crop: 'Corn', name: 'Common Rust', cat: 'fungal', desc: 'Oval reddish-brown pustules scattered prominently on both leaf surfaces.' },
    { crop: 'Corn', name: 'Northern Leaf Blight', cat: 'fungal', desc: 'Large elongated cigar-shaped grayish lesions on lower leaves progressing up.' },
    { crop: 'Corn', name: 'Healthy Leaf', cat: 'healthy', desc: 'Robust broad green blades with strong central midribs and healthy vigor.' },

    // Grape
    { crop: 'Grape', name: 'Black Rot', cat: 'fungal', desc: 'Reddish-brown circular spots developing tiny black fruiting bodies.' },
    { crop: 'Grape', name: 'Esca (Black Measles)', cat: 'fungal', desc: 'Striking "tiger-stripe" interveinal chlorosis and necrosis across canopy.' },
    { crop: 'Grape', name: 'Leaf Blight (Isariopsis)', cat: 'fungal', desc: 'Irregular brown necrotic lesions with faint reddish or chlorotic borders.' },
    { crop: 'Grape', name: 'Healthy Leaf', cat: 'healthy', desc: 'Expansive serrated leaves showing uniform green color and vigorous petioles.' },

    // Pepper
    { crop: 'Pepper', name: 'Bacterial Spot', cat: 'bacterial', desc: 'Small water-soaked blisters turning necrotic and causing widespread defoliation.' },
    { crop: 'Pepper', name: 'Healthy Leaf', cat: 'healthy', desc: 'Glossy dark green leaves with intact structure and clean veins.' },

    // Others
    { crop: 'Other', name: 'Strawberry Leaf Scorch', cat: 'fungal', desc: 'Dark purple irregular spots on leaves merging into scorched foliar margins.' },
    { crop: 'Other', name: 'Strawberry Healthy', cat: 'healthy', desc: 'Trifoliate bright green leaves without purplish spotting or wilting.' },
    { crop: 'Other', name: 'Peach Bacterial Spot', cat: 'bacterial', desc: 'Shot-hole effect where infected circular spots drop out of leaves.' },
    { crop: 'Other', name: 'Peach Healthy', cat: 'healthy', desc: 'Long lanceolate foliage displaying healthy chlorophyll density.' },
    { crop: 'Other', name: 'Cherry Powdery Mildew', cat: 'fungal', desc: 'White powdery fungal patches on foliage and young shoots, causing curling.' },
    { crop: 'Other', name: 'Cherry Healthy', cat: 'healthy', desc: 'Vibrant green canopy with clear veins and uncurled leaves.' },
    { crop: 'Other', name: 'Blueberry Healthy', cat: 'healthy', desc: 'Smooth elliptical leaves with vibrant green coloration and sturdy stems.' },
    { crop: 'Other', name: 'Orange Huanglongbing (Citrus Greening)', cat: 'bacterial', desc: 'Asymmetrical blotchy foliar mottle, yellow veins, and premature leaf drop.' },
    { crop: 'Other', name: 'Raspberry Healthy', cat: 'healthy', desc: 'Compound serrated leaves free of fungal cane blight or rust lesions.' },
    { crop: 'Other', name: 'Soybean Healthy', cat: 'healthy', desc: 'Pristine trifoliate foliage with balanced green pigment.' },
    { crop: 'Other', name: 'Squash Powdery Mildew', cat: 'fungal', desc: 'Dense white talcum-powder-like fungal colonies blanketing large leaves.' }
  ];

  const diseaseGrid = document.getElementById('diseaseGrid');
  const cropChips = document.querySelectorAll('.crop-chip');

  function renderDiseases(filter) {
    if (!diseaseGrid) return;
    diseaseGrid.innerHTML = '';

    const filtered = filter === 'all'
      ? plantClasses
      : plantClasses.filter(item => item.crop === filter);

    filtered.forEach(item => {
      const card = document.createElement('div');
      card.className = 'disease-card';
      const catClass = 'cat-' + item.cat;
      const catLabel = item.cat.charAt(0).toUpperCase() + item.cat.slice(1);

      card.innerHTML = `
        <div class="disease-card-crop">${item.crop}</div>
        <div class="disease-card-title">${item.name}</div>
        <span class="disease-category-tag ${catClass}">${catLabel}</span>
        <p class="disease-card-desc">${item.desc}</p>
      `;
      diseaseGrid.appendChild(card);
    });
  }

  cropChips.forEach(chip => {
    chip.addEventListener('click', () => {
      cropChips.forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      renderDiseases(chip.getAttribute('data-crop'));
    });
  });

  // Initial render of all 38 classes
  renderDiseases('all');

  // ─── 6. Docs Tab Navigation ───
  const docsBtns = document.querySelectorAll('.docs-btn');
  const docPanels = document.querySelectorAll('.doc-panel');

  docsBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const doc = btn.getAttribute('data-doc');
      docsBtns.forEach(b => b.classList.remove('active'));
      docPanels.forEach(p => p.classList.remove('active'));
      btn.classList.add('active');
      const targetDoc = document.getElementById('doc-' + doc);
      if (targetDoc) targetDoc.classList.add('active');
    });
  });

  // ─── 7. Copy Code Blocks ───
  document.querySelectorAll('.copy-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
      const codeEl = btn.closest('.code-box')?.querySelector('pre code');
      if (!codeEl) return;
      try {
        await navigator.clipboard.writeText(codeEl.innerText);
        const originalText = btn.textContent;
        btn.textContent = 'Copied!';
        btn.style.background = '#10b981';
        btn.style.color = '#ffffff';
        setTimeout(() => {
          btn.textContent = originalText;
          btn.style.background = '';
          btn.style.color = '';
        }, 2000);
      } catch (err) {
        console.error('Failed to copy text: ', err);
      }
    });
  });

  // ─── 8. Video Chapter Timestamp Seeker ───
  const mainDemoVideo = document.getElementById('mainDemoVideo');
  const mainVideoFallback = document.getElementById('mainVideoFallback');
  const chapterBtns = document.querySelectorAll('.chapter-btn');

  if (mainDemoVideo) {
    mainDemoVideo.addEventListener('error', () => {
      mainDemoVideo.style.display = 'none';
      if (mainVideoFallback) mainVideoFallback.style.display = 'flex';
    });

    chapterBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        const seconds = parseFloat(btn.getAttribute('data-time')) || 0;
        mainDemoVideo.currentTime = seconds;
        mainDemoVideo.play().catch(() => {});
        chapterBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        mainDemoVideo.scrollIntoView({ behavior: 'smooth', block: 'center' });
      });
    });
  }

  // ─── 9. Video Grid Cards & Modal Player ───
  const videoModal = document.getElementById('videoModal');
  const modalCloseBtn = document.getElementById('modalCloseBtn');
  const videoModalBackdrop = document.getElementById('videoModalBackdrop');
  const modalVideo = document.getElementById('modalVideo');
  const modalVideoTitle = document.getElementById('modalVideoTitle');
  const modalVideoDesc = document.getElementById('modalVideoDesc');
  const modalMissingCard = document.getElementById('modalMissingCard');
  const modalMissingText = document.getElementById('modalMissingText');
  const videoCards = document.querySelectorAll('.video-card');

  function openVideoModal(src, title, desc) {
    if (!videoModal) return;
    modalVideoTitle.textContent = title || 'Video Player';
    modalVideoDesc.textContent = desc || '';

    if (src) {
      modalVideo.style.display = 'block';
      modalMissingCard.style.display = 'none';
      const source = modalVideo.querySelector('source');
      if (source) source.src = src;
      modalVideo.load();
      modalVideo.play().catch(() => {});

      modalVideo.onerror = () => {
        modalVideo.style.display = 'none';
        modalMissingCard.style.display = 'block';
        modalMissingText.textContent = `The screen recording for "${title}" is not yet uploaded (${src}). Place your video in website/assets/videos/ or configure the link in content.json.`;
      };
    } else {
      modalVideo.style.display = 'none';
      modalMissingCard.style.display = 'block';
    }

    videoModal.classList.add('active');
    document.body.style.overflow = 'hidden';
  }

  function closeVideoModal() {
    if (!videoModal) return;
    videoModal.classList.remove('active');
    document.body.style.overflow = '';
    if (modalVideo) {
      modalVideo.pause();
      modalVideo.currentTime = 0;
    }
  }

  videoCards.forEach(card => {
    card.addEventListener('click', () => {
      const src = card.getAttribute('data-video-src');
      const title = card.getAttribute('data-video-title');
      const desc = card.getAttribute('data-video-desc');
      openVideoModal(src, title, desc);
    });
  });

  if (modalCloseBtn) modalCloseBtn.addEventListener('click', closeVideoModal);
  if (videoModalBackdrop) videoModalBackdrop.addEventListener('click', closeVideoModal);

  // Close modals on Escape key
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      closeVideoModal();
      if (window.closeLightbox) window.closeLightbox();
    }
  });

  // ─── 10. Screenshot Lightbox Modal ───
  window.openLightbox = function(src, caption) {
    const lightboxModal = document.getElementById('lightboxModal');
    const lightboxImg = document.getElementById('lightboxImg');
    const lightboxCaption = document.getElementById('lightboxCaption');
    if (!lightboxModal) return;

    lightboxImg.src = src;
    lightboxCaption.textContent = caption || '';
    lightboxModal.classList.add('active');
    document.body.style.overflow = 'hidden';
  };

  window.closeLightbox = function() {
    const lightboxModal = document.getElementById('lightboxModal');
    if (!lightboxModal) return;
    lightboxModal.classList.remove('active');
    document.body.style.overflow = '';
  };

});

package org.isetn.RestControllers;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.isetn.entities.ClassMat;
import org.isetn.entities.Etudiant;
import org.isetn.entities.Note;
import org.isetn.repository.ClassMatRepository;
import org.isetn.repository.EtudiantRepository;
import org.isetn.repository.NoteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/notes")
public class NoteController {

    @Autowired
    private NoteRepository noteRepository;

    @Autowired
    private EtudiantRepository etudiantRepository;

    @Autowired
    private ClassMatRepository classMatRepository;

    @GetMapping
    public List<Note> getAll() {
        return noteRepository.findAll();
    }

    @GetMapping("/etudiant/{etudiantId}")
    public List<Note> getByEtudiant(@PathVariable Integer etudiantId) {
        return noteRepository.findByEtudiantId(etudiantId);
    }

    @GetMapping("/classe/{codClass}/moyennes")
    public List<Map<String, Object>> getMoyennesByClasse(@PathVariable Integer codClass) {
        List<Etudiant> etudiants = etudiantRepository.findByClasseCodClass(codClass);
        List<ClassMat> classMats = classMatRepository.findByClasseCodClass(codClass);

        Map<String, Double> coefMap = new LinkedHashMap<>();
        for (ClassMat cm : classMats) {
            if (cm.getMatiere() != null) {
                coefMap.put(cm.getMatiere().getCodMat(), cm.getCoef() != null ? cm.getCoef() : 1.0);
            }
        }

        List<Map<String, Object>> result = new ArrayList<>();

        for (Etudiant e : etudiants) {
            List<Note> notes = noteRepository.findByEtudiantId(e.getId());
            double totalPoints = 0.0;
            double totalCoef = 0.0;

            for (Note n : notes) {
                if (n.getMatiere() == null) continue;
                String codMat = n.getMatiere().getCodMat();
                double coef = coefMap.getOrDefault(codMat, 1.0);

                double noteMat = calculateSubjectNote(n);
                totalPoints += noteMat * coef;
                totalCoef += coef;
            }

            Double moyenne = null;
            if (totalCoef > 0) {
                double avg = totalPoints / totalCoef;
                moyenne = BigDecimal.valueOf(avg).setScale(2, RoundingMode.HALF_UP).doubleValue();
            }

            Map<String, Object> map = new LinkedHashMap<>();
            map.put("id", e.getId());
            map.put("nom", e.getNom());
            map.put("prenom", e.getPrenom());
            map.put("moyenne", moyenne);
            result.add(map);
        }

        return result;
    }

    private double calculateSubjectNote(Note n) {
        Double tp1 = n.getTp1();
        Double tp2 = n.getTp2();
        Double ds = n.getDs() != null ? n.getDs() : 0.0;
        Double examen = n.getExamen() != null ? n.getExamen() : 0.0;

        if (tp1 != null || tp2 != null) {
            double tpAvg = 0.0;
            if (tp1 != null && tp2 != null) {
                tpAvg = (tp1 + tp2) / 2.0;
            } else if (tp1 != null) {
                tpAvg = tp1;
            } else {
                tpAvg = tp2;
            }
            return (tpAvg * 0.20) + (ds * 0.30) + (examen * 0.50);
        } else {
            return (ds * 0.30) + (examen * 0.70);
        }
    }

    @PostMapping
    public Note add(@RequestBody Note note) {
        return noteRepository.save(note);
    }
}
package org.isetn.RestControllers;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import org.isetn.entities.Absence;
import org.isetn.repository.AbsenceRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/absences")
public class AbsenceController {

    @Autowired
    private AbsenceRepository absenceRepository;

    @GetMapping
    public List<Absence> getAll() {
        return absenceRepository.findAll();
    }

    @GetMapping("/etudiant/{id}")
    public List<Absence> getByEtudiant(@PathVariable Integer id) {
        return absenceRepository.findByEtudiantId(id);
    }

    @GetMapping("/etudiant/{id}/totals")
    public List<Map<String, Object>> totals(@PathVariable Integer id) {
        Map<String, Double> sums = new TreeMap<>();
        for (Absence a : absenceRepository.findByEtudiantId(id)) {
            if (a.getMatiere() == null) continue;
            double h = a.getNha() == null ? 0.0 : a.getNha();
            sums.merge(a.getMatiere().getCodMat(), h, Double::sum);
        }
        List<Map<String, Object>> result = new ArrayList<>();
        for (Map.Entry<String, Double> e : sums.entrySet()) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("codMat", e.getKey());
            row.put("total", e.getValue());
            result.add(row);
        }
        return result;
    }

    @GetMapping("/top3-matieres")
    public List<Map<String, Object>> getTop3AbsencesMatieres() {
        Map<String, Object[]> map = new LinkedHashMap<>(); // codMat -> [intMat, totalNha]
        List<Absence> absences = absenceRepository.findAll();
        for (Absence a : absences) {
            if (a.getMatiere() == null) continue;
            String cod = a.getMatiere().getCodMat();
            String intMat = a.getMatiere().getIntMat() != null ? a.getMatiere().getIntMat() : cod;
            double nha = a.getNha() == null ? 0.0 : a.getNha();

            map.compute(cod, (k, v) -> {
                if (v == null) {
                    return new Object[]{intMat, nha};
                } else {
                    v[1] = (Double) v[1] + nha;
                    return v;
                }
            });
        }

        return map.entrySet().stream()
                .map(e -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("codMat", e.getKey());
                    m.put("intMat", e.getValue()[0]);
                    m.put("totalNha", e.getValue()[1]);
                    return m;
                })
                .sorted((a, b) -> Double.compare((Double) b.get("totalNha"), (Double) a.get("totalNha")))
                .limit(3)
                .toList();
    }

    @PostMapping
    public org.springframework.http.ResponseEntity<?> add(@RequestBody Absence a) {
        if (a.getNha() == null || a.getNha() <= 0 || a.getNha() > 3.0) {
            return org.springframework.http.ResponseEntity.badRequest()
                    .body("Le nombre d'heures d'absence doit être compris entre 0.5h et 3h max.");
        }
        return org.springframework.http.ResponseEntity.ok(absenceRepository.save(a));
    }

    @PutMapping("/{id}")
    public org.springframework.http.ResponseEntity<?> update(@PathVariable Integer id, @RequestBody Absence a) {
        if (a.getNha() == null || a.getNha() <= 0 || a.getNha() > 3.0) {
            return org.springframework.http.ResponseEntity.badRequest()
                    .body("Le nombre d'heures d'absence doit être compris entre 0.5h et 3h max.");
        }
        a.setId(id);
        return org.springframework.http.ResponseEntity.ok(absenceRepository.save(a));
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Integer id) {
        absenceRepository.deleteById(id);
    }
}